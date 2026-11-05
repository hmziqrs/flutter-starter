#ifndef RUNNER_NATIVE_SURFACES_H_
#define RUNNER_NATIVE_SURFACES_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "surface_snapshot.h"

// The Windows side of docs/native_surfaces.md: the method channel, the stored
// snapshot, and the system tray item that shows it.
class NativeSurfaces {
 public:
  // |window| is the app's top-level window, which owns the tray icon and
  // receives its messages. |launch_route| is held for takeLaunchRoute.
  NativeSurfaces(flutter::BinaryMessenger* messenger, HWND window,
                 std::string launch_route);
  ~NativeSurfaces();

  NativeSurfaces(const NativeSurfaces&) = delete;
  NativeSurfaces& operator=(const NativeSurfaces&) = delete;

  // Handles the messages the tray depends on. Returns a value when consumed.
  std::optional<LRESULT> HandleMessage(UINT message, WPARAM wparam,
                                       LPARAM lparam);

 private:
  using MethodCall = flutter::MethodCall<flutter::EncodableValue>;
  using MethodResult = flutter::MethodResult<flutter::EncodableValue>;

  void OnMethodCall(const MethodCall& call,
                    std::unique_ptr<MethodResult> result);
  bool Publish(const std::string& json);

  void AddTrayIcon();
  void RemoveTrayIcon();
  void UpdateTrayTooltip();
  void ShowTrayMenu(POINT anchor);
  void HandleCommand(UINT command);

  void RestoreWindow();
  void OpenRoute(const std::string& route);

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  SurfaceSnapshot snapshot_;
  HICON icon_ = nullptr;
  bool tray_added_ = false;
  UINT taskbar_created_message_ = 0;

  // The routes of the menu now on screen, which the snapshot can outrun.
  std::vector<std::string> menu_routes_;
  // A route waiting for Dart: the launch route, or one requested too early for
  // Dart's handler to exist.
  std::string pending_route_;
  bool dart_ready_ = false;
};

// Whether the Flutter tool started this process (`flutter run`, `flutter test`).
// Each such run is its own copy, so it never hands off to a running instance.
bool LaunchedByFlutterTool();

// Claims this user session's single instance. Returns false if another instance
// already holds it. The claim lasts until the process exits.
bool ClaimSingleInstance();

// Asks the running instance to come forward, opening |surface_url| if it is not
// empty. Returns false if no running instance answered.
bool HandOffToRunningInstance(const std::string& surface_url);

// Makes starter-surface: URLs open this executable, for the current user.
void RegisterSurfaceUrlScheme();

#endif  // RUNNER_NATIVE_SURFACES_H_
