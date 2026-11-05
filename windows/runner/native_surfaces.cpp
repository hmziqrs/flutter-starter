#include "native_surfaces.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <shlobj.h>
#include <windowsx.h>

#include <string>
#include <utility>

#include "resource.h"

namespace {

using flutter::EncodableValue;

constexpr wchar_t kAppId[] = L"com.example.starter";
constexpr wchar_t kInstanceMutex[] = L"Local\\com.example.starter.instance";
constexpr wchar_t kInstanceWindowProp[] = L"com.example.starter.instance";
constexpr wchar_t kUrlSchemeKey[] = L"Software\\Classes\\starter-surface";
constexpr char kChannelName[] = "starter/native_surfaces";

// Arbitrary, and checked so that other WM_COPYDATA senders pass through.
constexpr ULONG_PTR kHandOffId = 0x53555246;  // "SURF"
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;
constexpr UINT kCommandOpen = 1;
constexpr UINT kCommandQuit = 2;
constexpr UINT kCommandActionBase = 100;

std::wstring SnapshotPath() {
  PWSTR folder = nullptr;
  if (FAILED(::SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr,
                                    &folder))) {
    return std::wstring();
  }
  std::wstring path(folder);
  ::CoTaskMemFree(folder);
  path += L"\\";
  path += kAppId;
  ::CreateDirectoryW(path.c_str(), nullptr);
  return path + L"\\native_surfaces.json";
}

std::string ReadSnapshotFile() {
  const std::wstring path = SnapshotPath();
  HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ,
                              nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,
                              nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return std::string();
  }
  std::string contents;
  LARGE_INTEGER size = {};
  // Far larger than any snapshot, so a damaged file cannot exhaust memory.
  if (::GetFileSizeEx(file, &size) && size.QuadPart > 0 &&
      size.QuadPart < 1024 * 1024) {
    contents.resize(static_cast<size_t>(size.QuadPart));
    DWORD read = 0;
    if (!::ReadFile(file, contents.data(), static_cast<DWORD>(contents.size()),
                    &read, nullptr)) {
      read = 0;
    }
    contents.resize(read);
  }
  ::CloseHandle(file);
  return contents;
}

// Replaces the file in one step, so a widget never reads half a snapshot.
bool WriteSnapshotFile(const std::string& json) {
  const std::wstring path = SnapshotPath();
  if (path.empty()) {
    return false;
  }
  const std::wstring temp = path + L".tmp";
  HANDLE file = ::CreateFileW(temp.c_str(), GENERIC_WRITE, 0, nullptr,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return false;
  }
  DWORD written = 0;
  const BOOL wrote =
      ::WriteFile(file, json.data(), static_cast<DWORD>(json.size()), &written,
                  nullptr);
  ::CloseHandle(file);
  if (!wrote || written != json.size() ||
      !::MoveFileExW(temp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING)) {
    ::DeleteFileW(temp.c_str());
    return false;
  }
  return true;
}

// A plain ampersand would underline the next letter in a menu.
std::wstring MenuText(const std::wstring& text) {
  std::wstring escaped;
  escaped.reserve(text.size());
  for (const wchar_t c : text) {
    if (c == L'&') {
      escaped.push_back(L'&');
    }
    escaped.push_back(c);
  }
  return escaped;
}

NOTIFYICONDATAW TrayIconData(HWND window) {
  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window;
  data.uID = kTrayIconId;
  return data;
}

}  // namespace

NativeSurfaces::NativeSurfaces(flutter::BinaryMessenger* messenger, HWND window,
                               std::string launch_route)
    : window_(window),
      channel_(std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger, kChannelName,
          &flutter::StandardMethodCodec::GetInstance())),
      snapshot_(SurfaceSnapshot::Fallback()),
      pending_route_(std::move(launch_route)) {
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    OnMethodCall(call, std::move(result));
  });

  const std::string stored = ReadSnapshotFile();
  if (!stored.empty()) {
    snapshot_ = SurfaceSnapshot::Parse(stored);
  }

  ::SetPropW(window_, kInstanceWindowProp, window_);
  taskbar_created_message_ = ::RegisterWindowMessageW(L"TaskbarCreated");
  icon_ = static_cast<HICON>(::LoadImageW(
      ::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON),
      LR_DEFAULTCOLOR));
  AddTrayIcon();
}

NativeSurfaces::~NativeSurfaces() {
  channel_->SetMethodCallHandler(nullptr);
  RemoveTrayIcon();
  if (icon_) {
    ::DestroyIcon(icon_);
  }
  ::RemovePropW(window_, kInstanceWindowProp);
}

void NativeSurfaces::OnMethodCall(const MethodCall& call,
                                  std::unique_ptr<MethodResult> result) {
  dart_ready_ = true;
  const std::string& method = call.method_name();
  if (method == "publish") {
    const auto* json = std::get_if<std::string>(call.arguments());
    if (!json) {
      result->Error("bad_arguments", "publish takes snapshot JSON");
    } else if (!Publish(*json)) {
      result->Error("storage_failed", "could not write native_surfaces.json");
    } else {
      result->Success();
    }
  } else if (method == "takeLaunchRoute") {
    if (pending_route_.empty()) {
      result->Success();
    } else {
      result->Success(EncodableValue(pending_route_));
      pending_route_.clear();
    }
  } else if (method == "startLive") {
    // Windows has no ongoing lock screen presence.
    result->Success(EncodableValue(false));
  } else if (method == "updateLive" || method == "endLive") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

bool NativeSurfaces::Publish(const std::string& json) {
  const bool stored = WriteSnapshotFile(json);
  // The tray still follows the app when the disk does not. The Widgets Board
  // provider watches the file, so writing it is what redraws the widgets.
  snapshot_ = SurfaceSnapshot::Parse(json);
  UpdateTrayTooltip();
  return stored;
}

void NativeSurfaces::AddTrayIcon() {
  NOTIFYICONDATAW data = TrayIconData(window_);
  data.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = icon_;
  const std::wstring tooltip = snapshot_.Tooltip(ARRAYSIZE(data.szTip) - 1);
  ::wcsncpy_s(data.szTip, tooltip.c_str(), _TRUNCATE);
  tray_added_ = ::Shell_NotifyIconW(NIM_ADD, &data) != FALSE;
  if (tray_added_) {
    data.uVersion = NOTIFYICON_VERSION_4;
    ::Shell_NotifyIconW(NIM_SETVERSION, &data);
  }
}

void NativeSurfaces::RemoveTrayIcon() {
  if (tray_added_) {
    NOTIFYICONDATAW data = TrayIconData(window_);
    ::Shell_NotifyIconW(NIM_DELETE, &data);
    tray_added_ = false;
  }
}

void NativeSurfaces::UpdateTrayTooltip() {
  if (!tray_added_) {
    return;
  }
  NOTIFYICONDATAW data = TrayIconData(window_);
  data.uFlags = NIF_TIP | NIF_SHOWTIP;
  const std::wstring tooltip = snapshot_.Tooltip(ARRAYSIZE(data.szTip) - 1);
  ::wcsncpy_s(data.szTip, tooltip.c_str(), _TRUNCATE);
  ::Shell_NotifyIconW(NIM_MODIFY, &data);
}

void NativeSurfaces::ShowTrayMenu(POINT anchor) {
  HMENU menu = ::CreatePopupMenu();
  if (!menu) {
    return;
  }
  ::AppendMenuW(menu, MF_STRING | MF_GRAYED, 0,
                MenuText(snapshot_.title).c_str());
  if (!snapshot_.subtitle.empty()) {
    ::AppendMenuW(menu, MF_STRING | MF_GRAYED, 0,
                  MenuText(snapshot_.subtitle).c_str());
  }
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  menu_routes_.clear();
  for (const SurfaceAction& action : snapshot_.actions) {
    ::AppendMenuW(menu, MF_STRING, kCommandActionBase + menu_routes_.size(),
                  MenuText(action.label).c_str());
    menu_routes_.push_back(action.route);
  }
  if (!menu_routes_.empty()) {
    ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  }
  // The snapshot has no words for these two, and they do not depend on it.
  ::AppendMenuW(menu, MF_STRING, kCommandOpen, L"Open");
  ::AppendMenuW(menu, MF_STRING, kCommandQuit, L"Quit");

  // The menu only closes on an outside click if its owner is in the foreground.
  const HWND window = window_;
  ::SetForegroundWindow(window);
  UINT flags = TPM_RIGHTBUTTON;
  flags |= ::GetSystemMetrics(SM_MENUDROPALIGNMENT) != 0 ? TPM_RIGHTALIGN
                                                         : TPM_LEFTALIGN;
  // The menu runs its own message loop, and its choice arrives after it as
  // WM_COMMAND. |this| may be gone if the window was destroyed in the meantime.
  ::TrackPopupMenuEx(menu, flags, anchor.x, anchor.y, window, nullptr);
  ::PostMessageW(window, WM_NULL, 0, 0);
  ::DestroyMenu(menu);
}

void NativeSurfaces::HandleCommand(UINT command) {
  if (command == kCommandQuit) {
    // Destroys |this| on the way through FlutterWindow::OnDestroy.
    ::DestroyWindow(window_);
  } else if (command == kCommandOpen) {
    RestoreWindow();
    OpenRoute(snapshot_.route);
  } else if (command >= kCommandActionBase &&
             command - kCommandActionBase < menu_routes_.size()) {
    RestoreWindow();
    OpenRoute(menu_routes_[command - kCommandActionBase]);
  }
}

void NativeSurfaces::RestoreWindow() {
  ::ShowWindow(window_, ::IsIconic(window_) ? SW_RESTORE : SW_SHOW);
  ::SetForegroundWindow(window_);
}

void NativeSurfaces::OpenRoute(const std::string& route) {
  if (route.empty()) {
    return;
  }
  if (dart_ready_) {
    channel_->InvokeMethod("openRoute",
                           std::make_unique<EncodableValue>(route));
  } else {
    pending_route_ = route;
  }
}

std::optional<LRESULT> NativeSurfaces::HandleMessage(UINT message,
                                                     WPARAM wparam,
                                                     LPARAM lparam) {
  // Explorer restarted and forgot every tray icon, or was not up at launch.
  if (message == taskbar_created_message_ && taskbar_created_message_ != 0) {
    tray_added_ = false;
    AddTrayIcon();
    return 0;
  }
  switch (message) {
    case WM_CLOSE:
      // Without a tray icon there would be no way back, so closing quits.
      if (tray_added_) {
        ::ShowWindow(window_, SW_HIDE);
        return 0;
      }
      return std::nullopt;

    case kTrayMessage:
      // NOTIFYICON_VERSION_4: the event is in the low word of lparam, and the
      // anchor point is in wparam.
      switch (LOWORD(lparam)) {
        case NIN_SELECT:
        case NIN_KEYSELECT:
          HandleCommand(kCommandOpen);
          break;
        case WM_CONTEXTMENU:
          ShowTrayMenu(POINT{GET_X_LPARAM(wparam), GET_Y_LPARAM(wparam)});
          break;
      }
      return 0;

    case WM_COMMAND:
      if (HIWORD(wparam) == 0 && lparam == 0) {
        HandleCommand(LOWORD(wparam));
        return 0;
      }
      return std::nullopt;

    case WM_COPYDATA: {
      const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
      if (!data || data->dwData != kHandOffId) {
        return std::nullopt;
      }
      std::string url;
      if (data->lpData && data->cbData > 0) {
        url.assign(static_cast<const char*>(data->lpData), data->cbData);
      }
      RestoreWindow();
      OpenRoute(RouteFromSurfaceUrl(url));
      return TRUE;
    }
  }
  return std::nullopt;
}

bool LaunchedByFlutterTool() {
  return ::GetEnvironmentVariableW(L"FLUTTER_ENGINE_SWITCHES", nullptr, 0) > 0;
}

bool ClaimSingleInstance() {
  // Left open on purpose: Windows releases it when the process ends.
  ::CreateMutexW(nullptr, FALSE, kInstanceMutex);
  return ::GetLastError() != ERROR_ALREADY_EXISTS;
}

bool HandOffToRunningInstance(const std::string& surface_url) {
  // The running instance may still be starting, before its window exists.
  for (int attempt = 0; attempt < 30; ++attempt) {
    HWND running = nullptr;
    ::EnumWindows(
        [](HWND window, LPARAM found) -> BOOL {
          if (!::GetPropW(window, kInstanceWindowProp)) {
            return TRUE;
          }
          *reinterpret_cast<HWND*>(found) = window;
          return FALSE;
        },
        reinterpret_cast<LPARAM>(&running));
    if (running) {
      DWORD process_id = 0;
      ::GetWindowThreadProcessId(running, &process_id);
      ::AllowSetForegroundWindow(process_id);
      COPYDATASTRUCT data = {};
      data.dwData = kHandOffId;
      data.cbData = static_cast<DWORD>(surface_url.size());
      data.lpData = const_cast<char*>(surface_url.data());
      DWORD_PTR answer = 0;
      ::SendMessageTimeoutW(running, WM_COPYDATA, 0,
                            reinterpret_cast<LPARAM>(&data), SMTO_ABORTIFHUNG,
                            5000, &answer);
      return answer == TRUE;
    }
    ::Sleep(100);
  }
  return false;
}

void RegisterSurfaceUrlScheme() {
  std::wstring executable(32768, L'\0');
  const DWORD length = ::GetModuleFileNameW(
      nullptr, executable.data(), static_cast<DWORD>(executable.size()));
  if (length == 0 || length >= executable.size()) {
    return;
  }
  executable.resize(length);

  const auto set_value = [](const wchar_t* subkey, const wchar_t* name,
                            const std::wstring& value) {
    ::RegSetKeyValueW(HKEY_CURRENT_USER, subkey, name, REG_SZ, value.c_str(),
                      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  };
  const std::wstring command_key =
      std::wstring(kUrlSchemeKey) + L"\\shell\\open\\command";
  set_value(kUrlSchemeKey, nullptr, L"URL:Starter surface");
  set_value(kUrlSchemeKey, L"URL Protocol", L"");
  set_value(command_key.c_str(), nullptr, L"\"" + executable + L"\" \"%1\"");
}
