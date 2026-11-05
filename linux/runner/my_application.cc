#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "native_surfaces.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  // The route a surface launched the app with, until the channel takes it.
  char* launch_route;
  NativeSurfaces* native_surfaces;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Closing keeps the app in the tray, but only when there is a tray to come back
// from. Otherwise the default handler closes the window and the app quits.
static gboolean window_delete_cb(GtkWidget* window, GdkEvent* event,
                                 MyApplication* self) {
  if (self->native_surfaces == nullptr ||
      !native_surfaces_has_tray(self->native_surfaces)) {
    return FALSE;
  }
  gtk_widget_hide(window);
  return TRUE;
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  // A second launch comes back to this window, which may be hidden in the tray.
  if (self->native_surfaces != nullptr) {
    native_surfaces_restore_window(self->native_surfaces);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Starter");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Starter");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  self->native_surfaces = native_surfaces_new(FL_PLUGIN_REGISTRY(view), window,
                                              self->launch_route);
  g_clear_pointer(&self->launch_route, g_free);
  g_signal_connect(window, "delete-event", G_CALLBACK(window_delete_cb), self);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::open: another launch handed over a surface URL.
static void my_application_open(GApplication* application, GFile** files,
                                gint file_count, const gchar* hint) {
  MyApplication* self = MY_APPLICATION(application);
  g_application_activate(application);
  for (gint i = 0; i < file_count; ++i) {
    g_autofree gchar* url = g_file_get_uri(files[i]);
    g_autofree gchar* route = native_surfaces_route_from_url(url);
    native_surfaces_open_route(self->native_surfaces, route);
  }
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);

  // Strip out the first argument as it is the binary name, and a surface's URL,
  // which is for the native side and not Dart.
  const gchar* surface_url = nullptr;
  g_autoptr(GPtrArray) dart_arguments = g_ptr_array_new_with_free_func(g_free);
  for (gchar** argument = *arguments + 1; *argument != nullptr; ++argument) {
    if (surface_url == nullptr && native_surfaces_is_url(*argument)) {
      surface_url = *argument;
    } else {
      g_ptr_array_add(dart_arguments, g_strdup(*argument));
    }
  }
  g_ptr_array_add(dart_arguments, nullptr);
  self->dart_entrypoint_arguments = g_strdupv(
      reinterpret_cast<gchar**>(dart_arguments->pdata));

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  // The tray keeps the app alive with no window, so a second launch hands over
  // to the running app rather than adding a second icon.
  if (g_application_get_is_remote(application) && surface_url != nullptr) {
    g_autoptr(GFile) file = g_file_new_for_uri(surface_url);
    GFile* files[] = {file};
    g_application_open(application, files, 1, "");
  } else {
    self->launch_route = native_surfaces_route_from_url(surface_url);
    g_application_activate(application);
  }
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->native_surfaces, native_surfaces_free);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_pointer(&self->launch_route, g_free);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->open = my_application_open;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  // Each run by the Flutter tool is its own copy, and never hands off to another.
  const GApplicationFlags flags = g_getenv("FLUTTER_ENGINE_SWITCHES") != nullptr
                                      ? G_APPLICATION_NON_UNIQUE
                                      : G_APPLICATION_HANDLES_OPEN;
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     flags, nullptr));
}
