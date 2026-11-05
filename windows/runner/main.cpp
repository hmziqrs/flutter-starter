#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "native_surfaces.h"
#include "surface_snapshot.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // A surface opened this process: the URL is for the native side, not Dart.
  std::string surface_url;
  const auto surface_url_argument =
      std::find_if(command_line_arguments.begin(), command_line_arguments.end(),
                   IsSurfaceUrl);
  if (surface_url_argument != command_line_arguments.end()) {
    surface_url = *surface_url_argument;
    command_line_arguments.erase(surface_url_argument);
  }

  // The tray keeps the app alive with no window, so a second launch comes back
  // to the running app rather than adding a second icon.
  if (!LaunchedByFlutterTool()) {
    if (!ClaimSingleInstance() && HandOffToRunningInstance(surface_url)) {
      ::CoUninitialize();
      return EXIT_SUCCESS;
    }
    RegisterSurfaceUrlScheme();
  }

  flutter::DartProject project(L"data");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project, RouteFromSurfaceUrl(surface_url));
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Starter", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
