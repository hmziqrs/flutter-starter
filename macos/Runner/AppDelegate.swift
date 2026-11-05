import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var statusBar: SurfaceStatusBar?

  // The menu bar item outlives the window: closing it leaves the app running, and the Dock icon
  // or the menu's Open item brings it back. Quit is the way out.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    SurfaceFont.registerBundled()
    let routes = NativeSurfaces.shared.routes
    let statusBar = SurfaceStatusBar(
      onRoute: { [weak self] route in
        self?.bringWindowForward()
        routes.open(route: route)
      },
      onOpen: { [weak self] in self?.bringWindowForward() },
      onQuit: { NSApp.terminate(nil) }
    )
    NativeSurfaces.shared.snapshotDidChange = { [weak statusBar] in statusBar?.show($0) }
    self.statusBar = statusBar
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag { bringWindowForward() }
    return true
  }

  // Widgets open the app through this. `app_links` catches the same event and forwards it here.
  // It ignores this URL itself, because the host is not an allowed deep link host.
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where SurfaceLink.isSurfaceLink(url) {
      bringWindowForward()
      if let route = SurfaceLink.route(from: url) {
        NativeSurfaces.shared.routes.open(route: route)
      }
    }
    super.application(application, open: urls)
  }

  private func bringWindowForward() {
    NSApp.activate(ignoringOtherApps: true)
    guard let window = mainFlutterWindow else { return }
    if window.isMiniaturized { window.deminiaturize(nil) }
    window.makeKeyAndOrderFront(nil)
  }
}
