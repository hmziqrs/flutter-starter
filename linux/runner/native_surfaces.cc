#include "native_surfaces.h"

#include <string.h>

#ifdef HAVE_AYATANA_APPINDICATOR
#include <dlfcn.h>
#include <libayatana-appindicator/app-indicator.h>
#endif

namespace {

constexpr char kChannelName[] = "starter/native_surfaces";
constexpr char kSnapshotFile[] = "native_surfaces.json";
constexpr char kSurfaceScheme[] = "starter-surface:";
constexpr gint64 kKnownSchema = 1;

}  // namespace

struct _NativeSurfaces {
  GtkWindow* window;
  FlMethodChannel* channel;
  // A route waiting for Dart: the launch route, or one requested too early for
  // Dart's handler to exist.
  gchar* pending_route;
  gboolean dart_ready;
#ifdef HAVE_AYATANA_APPINDICATOR
  AppIndicator* indicator;
#endif
};

static gchar* snapshot_path() {
  return g_build_filename(g_get_user_data_dir(), APPLICATION_ID, kSnapshotFile,
                          nullptr);
}

// Stores the JSON in one step, so nothing ever reads half a snapshot.
static gboolean write_snapshot_file(const gchar* json) {
  g_autofree gchar* path = snapshot_path();
  g_autofree gchar* folder = g_path_get_dirname(path);
  if (g_mkdir_with_parents(folder, 0700) != 0) {
    return FALSE;
  }
  return g_file_set_contents(path, json, -1, nullptr);
}

#ifdef HAVE_AYATANA_APPINDICATOR

// A map to read a snapshot from, or null when the JSON is malformed or its
// schema is newer than this build knows. The caller falls back in that case.
static FlValue* parse_snapshot(const gchar* json) {
  if (json == nullptr || json[0] == '\0') {
    return nullptr;
  }
  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) value =
      fl_json_message_codec_decode(codec, json, &error);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* schema = fl_value_lookup_string(value, "schema");
  if (schema == nullptr || fl_value_get_type(schema) != FL_VALUE_TYPE_INT ||
      fl_value_get_int(schema) > kKnownSchema) {
    return nullptr;
  }
  FlValue* title = fl_value_lookup_string(value, "title");
  if (title == nullptr || fl_value_get_type(title) != FL_VALUE_TYPE_STRING ||
      fl_value_get_string(title)[0] == '\0') {
    return nullptr;
  }
  return fl_value_ref(value);
}

// The library is loaded when the app starts rather than linked, so that a build
// made where it exists still runs on a machine without it.
struct AppIndicatorLibrary {
  decltype(&app_indicator_new_with_path) new_with_path;
  decltype(&app_indicator_set_status) set_status;
  decltype(&app_indicator_set_menu) set_menu;
  decltype(&app_indicator_set_title) set_title;
};

static const AppIndicatorLibrary* app_indicator_library() {
  static AppIndicatorLibrary library;
  static gboolean loaded = FALSE;
  static gboolean tried = FALSE;
  if (!tried) {
    tried = TRUE;
    void* handle = dlopen("libayatana-appindicator3.so.1", RTLD_NOW);
    if (handle != nullptr) {
      library.new_with_path = reinterpret_cast<decltype(library.new_with_path)>(
          dlsym(handle, "app_indicator_new_with_path"));
      library.set_status = reinterpret_cast<decltype(library.set_status)>(
          dlsym(handle, "app_indicator_set_status"));
      library.set_menu = reinterpret_cast<decltype(library.set_menu)>(
          dlsym(handle, "app_indicator_set_menu"));
      library.set_title = reinterpret_cast<decltype(library.set_title)>(
          dlsym(handle, "app_indicator_set_title"));
      loaded = library.new_with_path != nullptr &&
               library.set_status != nullptr && library.set_menu != nullptr &&
               library.set_title != nullptr;
    }
  }
  return loaded ? &library : nullptr;
}

static void route_item_activated(GtkMenuItem* item, gpointer user_data) {
  auto* self = static_cast<NativeSurfaces*>(user_data);
  native_surfaces_restore_window(self);
  native_surfaces_open_route(
      self, static_cast<const gchar*>(
                g_object_get_data(G_OBJECT(item), "surface-route")));
}

static void quit_item_activated(GtkMenuItem* item, gpointer user_data) {
  auto* self = static_cast<NativeSurfaces*>(user_data);
  gtk_widget_destroy(GTK_WIDGET(self->window));
}

static void append_text_item(GtkWidget* menu, const gchar* text) {
  GtkWidget* item = gtk_menu_item_new_with_label(text);
  gtk_widget_set_sensitive(item, FALSE);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
}

static void append_route_item(NativeSurfaces* self, GtkWidget* menu,
                              const gchar* label, const gchar* route) {
  GtkWidget* item = gtk_menu_item_new_with_label(label);
  g_object_set_data_full(G_OBJECT(item), "surface-route", g_strdup(route),
                         g_free);
  g_signal_connect(item, "activate", G_CALLBACK(route_item_activated), self);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
}

static const gchar* string_field(FlValue* map, const gchar* key) {
  FlValue* value = map ? fl_value_lookup_string(map, key) : nullptr;
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : nullptr;
}

static void update_tray(NativeSurfaces* self, FlValue* snapshot) {
  const AppIndicatorLibrary* library = app_indicator_library();
  if (self->indicator == nullptr || library == nullptr) {
    return;
  }
  const gchar* title = snapshot ? string_field(snapshot, "title") : "Starter";
  const gchar* subtitle = snapshot ? string_field(snapshot, "subtitle")
                                   : "Open the app to get started";

  GtkWidget* menu = gtk_menu_new();
  append_text_item(menu, title);
  if (subtitle != nullptr && subtitle[0] != '\0') {
    append_text_item(menu, subtitle);
  }
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), gtk_separator_menu_item_new());

  FlValue* actions =
      snapshot ? fl_value_lookup_string(snapshot, "actions") : nullptr;
  size_t shown_actions = 0;
  if (actions != nullptr && fl_value_get_type(actions) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(actions); ++i) {
      FlValue* action = fl_value_get_list_value(actions, i);
      if (fl_value_get_type(action) != FL_VALUE_TYPE_MAP) {
        continue;
      }
      const gchar* label = string_field(action, "label");
      const gchar* route = string_field(action, "route");
      if (label != nullptr && route != nullptr && label[0] != '\0') {
        append_route_item(self, menu, label, route);
        ++shown_actions;
      }
    }
  }
  if (shown_actions > 0) {
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), gtk_separator_menu_item_new());
  }

  // The snapshot has no words for these two, and they do not depend on it.
  append_route_item(self, menu, "Open", string_field(snapshot, "route"));
  GtkWidget* quit = gtk_menu_item_new_with_label("Quit");
  g_signal_connect(quit, "activate", G_CALLBACK(quit_item_activated), self);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), quit);

  gtk_widget_show_all(menu);
  library->set_menu(self->indicator, GTK_MENU(menu));
  library->set_title(self->indicator, title);
}

static void start_tray(NativeSurfaces* self) {
  const AppIndicatorLibrary* library = app_indicator_library();
  if (library == nullptr) {
    return;
  }
  // The bundle keeps the icon next to its other data, beside the executable.
  g_autofree gchar* executable = g_file_read_link("/proc/self/exe", nullptr);
  if (executable == nullptr) {
    return;
  }
  g_autofree gchar* folder = g_path_get_dirname(executable);
  g_autofree gchar* icon_folder =
      g_build_filename(folder, "data", "tray", nullptr);
  self->indicator = library->new_with_path(
      APPLICATION_ID, "tray_icon", APP_INDICATOR_CATEGORY_APPLICATION_STATUS,
      icon_folder);
  if (self->indicator != nullptr) {
    library->set_status(self->indicator, APP_INDICATOR_STATUS_ACTIVE);
  }
}

// Asks the desktop whether anything is showing status items. GNOME without an
// extension, for one, shows none, and hiding the window there would strand it.
static gboolean status_notifier_host_present() {
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (bus == nullptr) {
    return FALSE;
  }
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      bus, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
      "org.freedesktop.DBus.Properties", "Get",
      g_variant_new("(ss)", "org.kde.StatusNotifierWatcher",
                    "IsStatusNotifierHostRegistered"),
      G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NO_AUTO_START, 500, nullptr,
      nullptr);
  if (reply == nullptr) {
    return FALSE;
  }
  g_autoptr(GVariant) value = nullptr;
  g_variant_get(reply, "(v)", &value);
  return g_variant_is_of_type(value, G_VARIANT_TYPE_BOOLEAN) &&
         g_variant_get_boolean(value);
}

#endif  // HAVE_AYATANA_APPINDICATOR

static void show_snapshot(NativeSurfaces* self, const gchar* json) {
#ifdef HAVE_AYATANA_APPINDICATOR
  g_autoptr(FlValue) snapshot = parse_snapshot(json);
  update_tray(self, snapshot);
#endif
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* call,
                           gpointer user_data) {
  auto* self = static_cast<NativeSurfaces*>(user_data);
  self->dart_ready = TRUE;
  const gchar* method = fl_method_call_get_name(call);
  FlValue* arguments = fl_method_call_get_args(call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, "publish") == 0) {
    if (arguments == nullptr ||
        fl_value_get_type(arguments) != FL_VALUE_TYPE_STRING) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "bad_arguments", "publish takes snapshot JSON", nullptr));
    } else {
      const gchar* json = fl_value_get_string(arguments);
      const gboolean stored = write_snapshot_file(json);
      // The tray still follows the app when the disk does not.
      show_snapshot(self, json);
      response =
          stored ? FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr))
                 : FL_METHOD_RESPONSE(fl_method_error_response_new(
                       "storage_failed", "could not write native_surfaces.json",
                       nullptr));
    }
  } else if (strcmp(method, "takeLaunchRoute") == 0) {
    g_autoptr(FlValue) route = self->pending_route != nullptr
                                   ? fl_value_new_string(self->pending_route)
                                   : nullptr;
    g_clear_pointer(&self->pending_route, g_free);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(route));
  } else if (strcmp(method, "startLive") == 0) {
    // Linux has no ongoing lock screen presence.
    g_autoptr(FlValue) started = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(started));
  } else if (strcmp(method, "updateLive") == 0 ||
             strcmp(method, "endLive") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

NativeSurfaces* native_surfaces_new(FlPluginRegistry* registry,
                                    GtkWindow* window,
                                    const gchar* launch_route) {
  auto* self = g_new0(NativeSurfaces, 1);
  self->window = window;
  self->pending_route = g_strdup(launch_route);

  g_autoptr(FlPluginRegistrar) registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NativeSurfaces");
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb, self,
                                            nullptr);

#ifdef HAVE_AYATANA_APPINDICATOR
  start_tray(self);
  g_autofree gchar* path = snapshot_path();
  g_autofree gchar* stored = nullptr;
  g_file_get_contents(path, &stored, nullptr, nullptr);
  show_snapshot(self, stored);
#endif
  return self;
}

void native_surfaces_free(NativeSurfaces* self) {
  if (self == nullptr) {
    return;
  }
  fl_method_channel_set_method_call_handler(self->channel, nullptr, nullptr,
                                            nullptr);
  g_clear_object(&self->channel);
#ifdef HAVE_AYATANA_APPINDICATOR
  g_clear_object(&self->indicator);
#endif
  g_free(self->pending_route);
  g_free(self);
}

void native_surfaces_restore_window(NativeSurfaces* self) {
  gtk_widget_show(GTK_WIDGET(self->window));
  gtk_window_present(self->window);
}

void native_surfaces_open_route(NativeSurfaces* self, const gchar* route) {
  if (route == nullptr || route[0] == '\0') {
    return;
  }
  if (self->dart_ready) {
    g_autoptr(FlValue) argument = fl_value_new_string(route);
    fl_method_channel_invoke_method(self->channel, "openRoute", argument,
                                    nullptr, nullptr, nullptr);
  } else {
    g_free(self->pending_route);
    self->pending_route = g_strdup(route);
  }
}

gboolean native_surfaces_has_tray(NativeSurfaces* self) {
#ifdef HAVE_AYATANA_APPINDICATOR
  return self->indicator != nullptr && status_notifier_host_present();
#else
  return FALSE;
#endif
}

gboolean native_surfaces_is_url(const gchar* argument) {
  return g_ascii_strncasecmp(argument, kSurfaceScheme,
                             strlen(kSurfaceScheme)) == 0;
}

gchar* native_surfaces_route_from_url(const gchar* url) {
  if (url == nullptr || !native_surfaces_is_url(url)) {
    return nullptr;
  }
  const gchar* query = strchr(url, '?');
  if (query == nullptr) {
    return nullptr;
  }
  g_autofree gchar* trimmed = g_strdup(query + 1);
  gchar* fragment = strchr(trimmed, '#');
  if (fragment != nullptr) {
    *fragment = '\0';
  }
  g_auto(GStrv) pairs = g_strsplit(trimmed, "&", -1);
  for (gchar** pair = pairs; *pair != nullptr; ++pair) {
    if (g_str_has_prefix(*pair, "route=")) {
      return g_uri_unescape_string(*pair + strlen("route="), nullptr);
    }
  }
  return nullptr;
}
