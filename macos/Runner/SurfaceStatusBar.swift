import AppKit

/// The menu bar item. Reads the stored snapshot at launch, so it shows the last known state
/// before Dart has started, and follows every `publish` after that.
final class SurfaceStatusBar: NSObject, NSMenuDelegate {
  private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private let menu = NSMenu()
  private let content: SurfaceMenuContent
  private let appName = SurfaceSnapshot.appName
  private var snapshot = SurfaceStore.load()
  private var isOpen = false

  init(
    onRoute: @escaping (String) -> Void,
    onOpen: @escaping () -> Void,
    onQuit: @escaping () -> Void
  ) {
    content = SurfaceMenuContent(onRoute: onRoute, onOpen: onOpen, onQuit: onQuit)
    super.init()
    menu.delegate = self
    item.menu = menu
    if let button = item.button {
      button.image = SurfaceMenuBarIcon.image(appName: appName)
      button.imagePosition = .imageLeading
      button.font = NSFont(name: SurfaceFont.medium, size: 12)
    }
    show(snapshot)
  }

  func show(_ snapshot: SurfaceSnapshot) {
    self.snapshot = snapshot
    item.button?.setAccessibilityLabel("\(snapshot.title), \(snapshot.subtitle)")
    // The figure beside the icon, while something is in progress.
    item.button?.title =
      snapshot.status == .active && snapshot.progress != nil ? snapshot.value ?? "" : ""
    if isOpen {
      content.header?.update(snapshot: snapshot)
    }
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    content.fill(menu, snapshot: snapshot, appName: appName)
  }

  func menuWillOpen(_ menu: NSMenu) { isOpen = true }
  func menuDidClose(_ menu: NSMenu) { isOpen = false }
}
