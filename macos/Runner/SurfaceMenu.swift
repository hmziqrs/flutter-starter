import AppKit
import SwiftUI

/// The top of the status menu: the snapshot's title, subtitle, figure and progress.
struct SurfaceMenuHeader: View {
  static let width: CGFloat = 280

  let snapshot: SurfaceSnapshot
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = SurfacePalette.forScheme(scheme)
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Text(snapshot.title)
          .font(palette.heading(13))
          .foregroundColor(palette.text)
          .lineLimit(1)
        Spacer(minLength: 8)
        SurfaceMarker(status: snapshot.status, palette: palette)
      }
      Text(snapshot.subtitle)
        .font(palette.body(12))
        .foregroundColor(palette.muted)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 3)
      if let value = snapshot.value {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(value)
            .font(palette.heading(26))
            .tracking(surfaceFigureTracking(value, size: 26))
            .foregroundColor(palette.text)
            .lineLimit(1)
          if let label = snapshot.valueLabel {
            Text(label)
              .font(palette.body(12))
              .foregroundColor(palette.muted)
              .lineLimit(1)
          }
        }
        .padding(.top, 10)
      }
      if let progress = snapshot.progress {
        SurfaceMenuProgress(
          progress: progress,
          tint: palette.color(for: snapshot.status),
          // A menu sits on the system's material, where the page's line color can vanish.
          track: palette.text.opacity(0.14)
        )
        .padding(.top, 8)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .frame(width: Self.width, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

private struct SurfaceMenuProgress: View {
  let progress: Double
  let tint: Color
  let track: Color

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(track)
        Capsule().fill(tint).frame(width: max(4, proxy.size.width * progress))
      }
    }
    .frame(height: 4)
  }
}

/// A menu item's view. Takes the whole click itself so the menu closes like any other item.
final class SurfaceMenuHeaderView: NSView {
  private let hosting: NSHostingView<SurfaceMenuHeader>
  private let onChoose: () -> Void

  init(snapshot: SurfaceSnapshot, onChoose: @escaping () -> Void) {
    hosting = NSHostingView(rootView: SurfaceMenuHeader(snapshot: snapshot))
    self.onChoose = onChoose
    super.init(frame: NSRect(origin: .zero, size: hosting.fittingSize))
    hosting.frame = bounds
    hosting.autoresizingMask = [.width, .height]
    addSubview(hosting)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  func update(snapshot: SurfaceSnapshot) {
    hosting.rootView = SurfaceMenuHeader(snapshot: snapshot)
    setFrameSize(hosting.fittingSize)
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    frame.contains(point) ? self : nil
  }

  override func mouseUp(with event: NSEvent) {
    enclosingMenuItem?.menu?.cancelTracking()
    onChoose()
  }

  override func draw(_ dirtyRect: NSRect) {
    guard enclosingMenuItem?.isHighlighted == true else { return }
    NSColor.labelColor.withAlphaComponent(0.08).setFill()
    NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 0), xRadius: 5, yRadius: 5).fill()
  }
}

/// Fills the status menu from a snapshot. Knows nothing about the status bar, so its items can be
/// built and triggered without putting anything on the owner's screen.
final class SurfaceMenuContent: NSObject {
  /// The snapshot has no words for these two, and they name the app rather than its content.
  static func openLabel(appName: String) -> String { "Open \(appName)" }
  static func quitLabel(appName: String) -> String { "Quit \(appName)" }

  private let onRoute: (String) -> Void
  private let onOpen: () -> Void
  private let onQuit: () -> Void
  private(set) var header: SurfaceMenuHeaderView?

  init(
    onRoute: @escaping (String) -> Void,
    onOpen: @escaping () -> Void,
    onQuit: @escaping () -> Void
  ) {
    self.onRoute = onRoute
    self.onOpen = onOpen
    self.onQuit = onQuit
  }

  func fill(_ menu: NSMenu, snapshot: SurfaceSnapshot, appName: String) {
    menu.removeAllItems()
    menu.autoenablesItems = false

    let headerItem = NSMenuItem()
    headerItem.title = "\(snapshot.title), \(snapshot.subtitle)"
    let route = snapshot.route
    let header = SurfaceMenuHeaderView(snapshot: snapshot) { [weak self] in self?.onRoute(route) }
    headerItem.view = header
    self.header = header
    menu.addItem(headerItem)
    menu.addItem(.separator())

    for action in snapshot.actions {
      let item = makeItem(title: action.label, selector: #selector(chooseRoute(_:)))
      item.representedObject = action.route
      menu.addItem(item)
    }
    if !snapshot.actions.isEmpty { menu.addItem(.separator()) }

    menu.addItem(
      makeItem(title: Self.openLabel(appName: appName), selector: #selector(chooseOpen(_:))))
    let quit = makeItem(title: Self.quitLabel(appName: appName), selector: #selector(chooseQuit(_:)))
    quit.keyEquivalent = "q"
    menu.addItem(quit)
  }

  private func makeItem(title: String, selector: Selector) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
    item.target = self
    if let font = NSFont(name: SurfaceFont.regular, size: 13) {
      item.attributedTitle = NSAttributedString(string: title, attributes: [.font: font])
    }
    return item
  }

  @objc private func chooseRoute(_ sender: NSMenuItem) {
    if let route = sender.representedObject as? String { onRoute(route) }
  }

  @objc private func chooseOpen(_ sender: NSMenuItem) { onOpen() }
  @objc private func chooseQuit(_ sender: NSMenuItem) { onQuit() }
}

/// The brand's Mark for the menu bar: the app's two letters and the square, knocked out of a
/// rounded tile. Drawn rather than stored, so renaming the app redraws it. A template image, so
/// the system tints it for the menu bar's appearance.
enum SurfaceMenuBarIcon {
  static func image(appName: String) -> NSImage {
    let symbol = symbol(appName: appName)
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
      draw(symbol: symbol, in: rect)
      return true
    }
    image.isTemplate = true
    return image
  }

  private static func draw(symbol: String, in rect: NSRect) {
    let tile = rect.insetBy(dx: 1, dy: 1)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.22, yRadius: tile.width * 0.22).fill()

    let font =
      NSFont(name: SurfaceFont.semiBold, size: 9.5)
      ?? NSFont.systemFont(ofSize: 9.5, weight: .semibold)
    let letters = NSAttributedString(
      string: symbol,
      attributes: [.font: font, .foregroundColor: NSColor.black, .kern: -0.2]
    )
    let textSize = letters.size()
    let squareSide: CGFloat = 2.4
    let gap: CGFloat = 0.5
    let origin = NSPoint(
      x: tile.midX - (textSize.width + gap + squareSide) / 2,
      y: tile.midY - textSize.height / 2
    )
    NSGraphicsContext.current?.compositingOperation = .destinationOut
    letters.draw(at: origin)
    NSRect(
      x: origin.x + textSize.width + gap,
      y: origin.y - font.descender,
      width: squareSide,
      height: squareSide
    ).fill(using: .destinationOut)
  }

  /// The same two letters `just brand-assets` draws by default: the name's first two.
  private static func symbol(appName: String) -> String {
    let letters = appName.filter { $0.isLetter || $0.isNumber }.prefix(2)
    return letters.prefix(1).uppercased() + letters.dropFirst().lowercased()
  }
}
