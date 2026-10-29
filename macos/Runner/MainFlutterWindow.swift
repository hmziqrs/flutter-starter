import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // A roomy default so the expanded shell and the dev gallery's
    // side-by-side layout open from the first launch (≥ the wide
    // breakpoint). The window opts out of macOS frame restoration: the app
    // restores its own state (route, settings), and a stale saved frame
    // overrode this default on every relaunch.
    isRestorable = false
    setFrame(NSRect(x: 0, y: 0, width: 1360, height: 900), display: true)
    center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
