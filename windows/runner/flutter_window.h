#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>
#include <string>

#include "native_surfaces.h"
#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  // |launch_route| is the route a native surface launched the app with, if any.
  FlutterWindow(const flutter::DartProject& project, std::string launch_route);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // The route to hand to the native surfaces once the engine exists.
  std::string launch_route_;

  // The tray and the method channel behind it. Needs flutter_controller_.
  std::unique_ptr<NativeSurfaces> native_surfaces_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
