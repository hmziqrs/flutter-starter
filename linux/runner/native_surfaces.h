#ifndef RUNNER_NATIVE_SURFACES_H_
#define RUNNER_NATIVE_SURFACES_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// The Linux side of docs/native_surfaces.md: the method channel, the stored
// snapshot, and a tray item where the desktop has one.
typedef struct _NativeSurfaces NativeSurfaces;

// Starts the channel and, when the AppIndicator library is present, the tray.
// |window| must outlive the result. |launch_route| may be null.
NativeSurfaces* native_surfaces_new(FlPluginRegistry* registry,
                                    GtkWindow* window,
                                    const gchar* launch_route);

void native_surfaces_free(NativeSurfaces* self);

// Brings the window back, wherever it was.
void native_surfaces_restore_window(NativeSurfaces* self);

// Sends |route| to Dart. Null or empty does nothing.
void native_surfaces_open_route(NativeSurfaces* self, const gchar* route);

// Whether the desktop is showing the tray item right now, which is what makes
// it safe to hide the window instead of quitting.
gboolean native_surfaces_has_tray(NativeSurfaces* self);

// Whether |argument| is a starter-surface: URL.
gboolean native_surfaces_is_url(const gchar* argument);

// The decoded route from starter-surface://open?route=<percent-encoded route>,
// or null. Dart checks routes, so this does not. Free with g_free.
gchar* native_surfaces_route_from_url(const gchar* url);

#endif  // RUNNER_NATIVE_SURFACES_H_
