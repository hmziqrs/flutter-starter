#ifndef RUNNER_SURFACE_SNAPSHOT_H_
#define RUNNER_SURFACE_SNAPSHOT_H_

#include <string>
#include <vector>

// One entry in a surface's menu.
struct SurfaceAction {
  std::wstring label;
  std::string route;
};

// The parts of a snapshot the tray shows. See docs/native_surfaces.md.
struct SurfaceSnapshot {
  std::wstring title;
  std::wstring subtitle;
  std::wstring value;
  std::wstring value_label;
  // Empty in the fallback, which has nowhere to send the app.
  std::string route;
  std::vector<SurfaceAction> actions;

  // What surfaces show before anything has been published.
  static SurfaceSnapshot Fallback();

  // Reads snapshot JSON. Returns the fallback when the JSON is malformed or its
  // schema is newer than this build knows.
  static SurfaceSnapshot Parse(const std::string& json);

  // The tooltip text, at most |max_length| UTF-16 units.
  std::wstring Tooltip(size_t max_length) const;
};

// Whether |argument| is a starter-surface: URL.
bool IsSurfaceUrl(const std::string& argument);

// The decoded route from starter-surface://open?route=<percent-encoded route>,
// or an empty string. Dart checks routes, so this does not.
std::string RouteFromSurfaceUrl(const std::string& url);

#endif  // RUNNER_SURFACE_SNAPSHOT_H_
