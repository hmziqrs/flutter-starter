// Headless checks and renders for the macOS surfaces. Opens no window, puts nothing in the menu
// bar, and posts no input. See run.sh.
//
//   render <output dir>       writes every widget family and the menu to PNG, dark and light
//   check                     tests the snapshot, the channel, the routes and the menu's items
//   store-write <suite> <json>  writes a snapshot the way `publish` does
//   store-read <suite>          prints what a widget would read, as a second process

import AppKit
import SwiftUI
import WidgetKit

let arguments = CommandLine.arguments

@MainActor
func run() -> Int32 {
  switch arguments.dropFirst().first {
  case "render":
    guard arguments.count == 4 else { return usage() }
    SurfaceFont.register(urls: fontURLs(in: arguments[3]))
    return render(to: URL(fileURLWithPath: arguments[2], isDirectory: true))
  case "check":
    SurfaceFont.register(urls: fontURLs(in: arguments.count > 2 ? arguments[2] : "."))
    return check()
  case "store-write":
    guard arguments.count == 4, let defaults = SurfaceStore.defaults(suite: arguments[2]) else {
      return usage()
    }
    SurfaceStore.write(json: arguments[3], to: defaults)
    defaults.synchronize()
    return 0
  case "store-read":
    guard arguments.count == 3 else { return usage() }
    let snapshot = SurfaceStore.load(from: SurfaceStore.defaults(suite: arguments[2]))
    print("\(snapshot.title)|\(snapshot.subtitle)|\(snapshot.value ?? "-")|\(snapshot.status)")
    return 0
  default:
    return usage()
  }
}

func usage() -> Int32 {
  print("usage: render <dir> <fonts dir> | check <fonts dir> | store-write <suite> <json> | store-read <suite>")
  return 2
}

func fontURLs(in directory: String) -> [URL] {
  let root = URL(fileURLWithPath: directory, isDirectory: true)
  return (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil))?
    .filter { $0.pathExtension == "ttf" } ?? []
}

// MARK: Sample data

let sampleActions = [
  SurfaceAction(label: "Home", route: "/"),
  SurfaceAction(label: "Pricing", route: "/pricing"),
  SurfaceAction(label: "Settings", route: "/settings"),
]
let sampleDate = Date(timeIntervalSince1970: 1_793_000_000)

let samples: [(name: String, snapshot: SurfaceSnapshot)] = [
  (
    "running",
    SurfaceSnapshot(
      title: "Starter", subtitle: "Build running", value: "72%", valueLabel: "Complete",
      progress: 0.72, status: .active, updatedAt: sampleDate, actions: sampleActions)
  ),
  (
    "finished",
    SurfaceSnapshot(
      title: "Starter", subtitle: "Build finished", value: "100%", valueLabel: "Complete",
      progress: 1, status: .success, updatedAt: sampleDate, actions: sampleActions)
  ),
  (
    "failed",
    SurfaceSnapshot(
      title: "Starter", subtitle: "Build failed", value: "38%", valueLabel: "Complete",
      progress: 0.38, status: .failure, updatedAt: sampleDate, actions: sampleActions)
  ),
  (
    "figure",
    SurfaceSnapshot(
      title: "Starter", subtitle: "Up 12% this week", value: "48,210", valueLabel: "Visitors",
      status: .warning, updatedAt: sampleDate, actions: sampleActions)
  ),
  ("fallback", SurfaceSnapshot(title: "Starter", subtitle: "Open the app to get started")),
  // What the app publishes at launch (`_surfaceSnapshot` in lib/app/app.dart).
  (
    "launch",
    SurfaceSnapshot(
      title: "Starter", subtitle: "Your starter is set up and ready for the next real feature.",
      updatedAt: sampleDate, actions: sampleActions)
  ),
  (
    "long",
    SurfaceSnapshot(
      title: "Starter Enterprise Edition for Teams",
      subtitle: "Deploying the production release to every region, which takes a while",
      value: "1,234,567", valueLabel: "Requests handled in the last hour",
      progress: 0.4, status: .warning, updatedAt: sampleDate,
      actions: [
        SurfaceAction(label: "Very long action label that cannot possibly fit", route: "/a"),
        SurfaceAction(label: "Pricing", route: "/pricing"),
        SurfaceAction(label: "Settings", route: "/settings"),
        SurfaceAction(label: "Profile", route: "/profile"),
        SurfaceAction(label: "Never shown", route: "/hidden"),
      ])
  ),
]

// MARK: Rendering

/// macOS's widget sizes, in points, on a 14-inch display.
let families: [(name: String, family: WidgetFamily, size: CGSize)] = [
  ("small", .systemSmall, CGSize(width: 158, height: 158)),
  ("medium", .systemMedium, CGSize(width: 338, height: 158)),
  ("large", .systemLarge, CGSize(width: 338, height: 354)),
]

struct WidgetFrame<Content: View>: View {
  let size: CGSize
  let background: Color
  @ViewBuilder let content: Content

  var body: some View {
    content
      .frame(width: size.width, height: size.height)
      .background(background)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
  }
}

/// The surroundings: a soft desktop, so a widget's edge and corners can be judged.
struct Desktop<Content: View>: View {
  let scheme: ColorScheme
  @ViewBuilder let content: Content

  var body: some View {
    content
      .padding(20)
      .background(scheme == .dark ? Color(hex: 0x3B3F46) : Color(hex: 0xC9D2DC))
      .environment(\.colorScheme, scheme)
  }
}

/// The status menu as AppKit draws it around the real header view. AppKit's own menu chrome can
/// only be drawn on screen, so its panel, rows and separators are stand-ins at its metrics.
struct MenuStandIn: View {
  let snapshot: SurfaceSnapshot
  let appName: String
  let scheme: ColorScheme

  private var ink: Color { scheme == .dark ? .white.opacity(0.92) : .black.opacity(0.88) }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SurfaceMenuHeader(snapshot: snapshot)
      separator
      ForEach(Array(snapshot.actions.enumerated()), id: \.offset) { _, action in row(action.label) }
      if !snapshot.actions.isEmpty { separator }
      row(SurfaceMenuContent.openLabel(appName: appName))
      row(SurfaceMenuContent.quitLabel(appName: appName), key: "\u{2318}Q")
    }
    .padding(.vertical, 5)
    .frame(width: SurfaceMenuHeader.width)
    .background(scheme == .dark ? Color(hex: 0x2A2A2C) : Color(hex: 0xF4F4F5))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.12))
    )
  }

  private var separator: some View {
    Rectangle()
      .fill(scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
      .frame(height: 1)
      .padding(.horizontal, 14)
      .padding(.vertical, 5)
  }

  private func row(_ title: String, key: String? = nil) -> some View {
    HStack {
      Text(title).font(.custom(SurfaceFont.regular, fixedSize: 13)).foregroundColor(ink)
      Spacer()
      if let key = key {
        Text(key).font(.system(size: 13)).foregroundColor(ink.opacity(0.5))
      }
    }
    .frame(height: 22)
    .padding(.horizontal, 14)
  }
}

@MainActor
func savePNG<Content: View>(_ view: Content, to url: URL) throws {
  let renderer = ImageRenderer(content: view)
  renderer.scale = 2
  guard
    let cgImage = renderer.cgImage,
    let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])
  else { throw CocoaError(.fileWriteUnknown) }
  try data.write(to: url)
}

/// Draws the template icon the way the system tints it, on a stretch of menu bar.
func menuBarStrip(scheme: ColorScheme, value: String?) -> NSImage {
  let icon = SurfaceMenuBarIcon.image(appName: "Starter")
  let tint: NSColor = scheme == .dark ? .white : .black
  let tinted = NSImage(size: icon.size, flipped: false) { rect in
    icon.draw(in: rect)
    tint.setFill()
    rect.fill(using: .sourceIn)
    return true
  }
  let strip = NSImage(size: NSSize(width: 120, height: 24), flipped: false) { rect in
    (scheme == .dark ? NSColor(white: 0.16, alpha: 1) : NSColor(white: 0.93, alpha: 1)).setFill()
    rect.fill()
    tinted.draw(in: NSRect(x: 8, y: 3, width: 18, height: 18))
    if let value = value {
      NSAttributedString(
        string: value,
        attributes: [
          .font: NSFont(name: SurfaceFont.medium, size: 12) ?? .systemFont(ofSize: 12),
          .foregroundColor: tint,
        ]
      ).draw(at: NSPoint(x: 30, y: 4))
    }
    return true
  }
  return strip
}

func savePNG(_ image: NSImage, to url: URL, scale: CGFloat) throws {
  let pixels = NSSize(width: image.size.width * scale, height: image.size.height * scale)
  guard
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: Int(pixels.width), pixelsHigh: Int(pixels.height),
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
  else { throw CocoaError(.fileWriteUnknown) }
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  image.draw(in: NSRect(origin: .zero, size: pixels))
  NSGraphicsContext.restoreGraphicsState()
  guard let data = bitmap.representation(using: .png, properties: [:]) else {
    throw CocoaError(.fileWriteUnknown)
  }
  try data.write(to: url)
}

@MainActor
func render(to directory: URL) -> Int32 {
  do {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for (schemeName, scheme) in [("dark", ColorScheme.dark), ("light", ColorScheme.light)] {
      let palette = SurfacePalette.forScheme(scheme)
      for sample in samples {
        for entry in families {
          try savePNG(
            Desktop(scheme: scheme) {
              WidgetFrame(size: entry.size, background: palette.page) {
                SurfaceWidgetContent(
                  snapshot: sample.snapshot, family: entry.family, palette: palette)
              }
            },
            to: directory.appendingPathComponent(
              "widget-\(entry.name)-\(sample.name)-\(schemeName).png"))
        }
        try savePNG(
          Desktop(scheme: scheme) {
            MenuStandIn(snapshot: sample.snapshot, appName: "Starter", scheme: scheme)
          },
          to: directory.appendingPathComponent("menu-\(sample.name)-\(schemeName).png"))
      }
      try savePNG(
        menuBarStrip(scheme: scheme, value: nil),
        to: directory.appendingPathComponent("menubar-icon-\(schemeName).png"), scale: 4)
      try savePNG(
        menuBarStrip(scheme: scheme, value: "72%"),
        to: directory.appendingPathComponent("menubar-progress-\(schemeName).png"), scale: 4)
    }
    return 0
  } catch {
    print("render failed: \(error)")
    return 1
  }
}

// MARK: Checks

var failures = 0

func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
  if condition() {
    print("ok    \(name)")
  } else {
    failures += 1
    print("FAIL  \(name)")
  }
}

@MainActor
func check() -> Int32 {
  checkSnapshot()
  checkLinks()
  checkRoutes()
  checkChannel()
  checkMenu()
  print(failures == 0 ? "all checks passed" : "\(failures) checks failed")
  return failures == 0 ? 0 : 1
}

let contractSample = """
  {"schema":1,"title":"Starter","subtitle":"Build running","value":"72%","valueLabel":"Complete",\
  "progress":0.72,"status":"active","updatedAt":"2026-11-05T01:00:00.000Z","route":"/",\
  "actions":[{"label":"Pricing","route":"/pricing"}]}
  """

func checkSnapshot() {
  let full = SurfaceSnapshot.decode(json: contractSample)
  expect(full?.title == "Starter" && full?.subtitle == "Build running", "reads the title and subtitle")
  expect(full?.value == "72%" && full?.valueLabel == "Complete", "reads the value and its label")
  expect(full?.progress == 0.72 && full?.status == .active, "reads the progress and status")
  expect(full?.updatedAt != nil, "reads a date with fractional seconds, as Dart writes it")
  expect(full?.actions == [SurfaceAction(label: "Pricing", route: "/pricing")], "reads the actions")

  let nulls = SurfaceSnapshot.decode(
    json: #"{"schema":1,"title":"T","subtitle":"S","value":null,"valueLabel":null,"progress":null,"status":"idle","updatedAt":"2026-11-05T01:00:00.000Z","route":"/pricing","actions":[]}"#)
  expect(nulls?.value == nil && nulls?.valueLabel == nil && nulls?.progress == nil, "null fields stay missing")
  expect(nulls?.route == "/pricing", "keeps the route")

  expect(
    SurfaceSnapshot.decode(json: #"{"schema":2,"title":"T","subtitle":"S"}"#) == nil,
    "ignores a newer schema")
  expect(SurfaceSnapshot.decode(json: "not json") == nil, "ignores malformed JSON")
  expect(
    SurfaceSnapshot.decode(json: #"{"schema":1,"title":"T","subtitle":"S","status":"new"}"#)?.status == .idle,
    "an unknown status reads as idle")
  expect(
    SurfaceSnapshot.decode(json: #"{"schema":1,"title":"T","subtitle":"S","progress":1.4}"#)?.progress == 1,
    "clamps the progress")
  expect(
    SurfaceSnapshot.decode(json: #"{"schema":1,"title":"T","subtitle":"S","progress":1}"#)?.progress == 1,
    "reads a whole-number progress")

  let suite = "surface.check.\(ProcessInfo.processInfo.processIdentifier)"
  let defaults = UserDefaults(suiteName: suite)
  defer { defaults?.removePersistentDomain(forName: suite) }
  expect(SurfaceStore.load(from: defaults) == .fallback, "nothing published shows the fallback")
  expect(SurfaceSnapshot.fallback.subtitle == "Open the app to get started", "the fallback's words")
  SurfaceStore.write(json: contractSample, to: defaults)
  expect(SurfaceStore.load(from: defaults).title == "Starter", "reads back what was written")
  expect(defaults?.string(forKey: "surface.snapshot") == contractSample, "stores the JSON under the contract's key")
  SurfaceStore.write(json: #"{"schema":9,"title":"Future","subtitle":"S"}"#, to: defaults)
  expect(SurfaceStore.load(from: defaults) == .fallback, "a stored newer schema shows the fallback")
}

func checkLinks() {
  expect(
    SurfaceLink.url(route: "/pricing").absoluteString == "starter-surface://open?route=%2Fpricing",
    "builds the contract's URL")
  for route in ["/", "/pricing", "/a b?x=1&y=2#z", "/caf\u{e9}"] {
    expect(SurfaceLink.route(from: SurfaceLink.url(route: route)) == route, "round-trips \(route)")
  }
  expect(
    SurfaceLink.route(from: URL(string: "https://open?route=%2Fx")!) == nil,
    "ignores another scheme")
  expect(
    !SurfaceLink.isSurfaceLink(URL(string: "starter-surface://other?route=%2Fx")!),
    "ignores another host")
}

func checkRoutes() {
  let cold = SurfaceRouteDesk()
  var delivered: [String] = []
  cold.deliver = { delivered.append($0) }
  cold.open(route: "/pricing")
  expect(delivered.isEmpty, "a cold launch holds the route instead of calling openRoute")
  expect(cold.takeLaunchRoute() == "/pricing", "takeLaunchRoute returns the held route")
  expect(cold.takeLaunchRoute() == nil, "takeLaunchRoute then returns null")
  cold.open(route: "/settings")
  expect(delivered == ["/settings"], "once Dart is listening, routes go to openRoute")
  expect(cold.takeLaunchRoute() == nil, "a route sent to openRoute is not returned again")
}

func checkChannel() {
  let routes = SurfaceRouteDesk()
  var published: [String] = []
  let core = SurfaceChannelCore(routes: routes) { published.append($0) }

  if case .value(let value) = core.handle(method: "publish", argument: contractSample) {
    expect(value == nil && published == [contractSample], "publish hands over the JSON")
  } else {
    expect(false, "publish hands over the JSON")
  }
  if case .badArgument = core.handle(method: "publish", argument: 3) {
    expect(published.count == 1, "publish refuses anything but a string")
  } else {
    expect(false, "publish refuses anything but a string")
  }
  if case .value(let value) = core.handle(method: "startLive", argument: contractSample) {
    expect((value as? Bool) == false, "startLive returns false")
  } else {
    expect(false, "startLive returns false")
  }
  for method in ["updateLive", "endLive"] {
    if case .value(let value) = core.handle(method: method, argument: nil) {
      expect(value == nil, "\(method) does nothing")
    } else {
      expect(false, "\(method) does nothing")
    }
  }
  routes.open(route: "/held")
  if case .value(let value) = core.handle(method: "takeLaunchRoute", argument: nil) {
    expect((value as? String) == "/held", "takeLaunchRoute answers over the channel")
  } else {
    expect(false, "takeLaunchRoute answers over the channel")
  }
  if case .notImplemented = core.handle(method: "nonsense", argument: nil) {
    expect(true, "an unknown method is not implemented")
  } else {
    expect(false, "an unknown method is not implemented")
  }
}

@MainActor
func checkMenu() {
  var routes: [String] = []
  var opened = 0
  var quit = 0
  let content = SurfaceMenuContent(
    onRoute: { routes.append($0) }, onOpen: { opened += 1 }, onQuit: { quit += 1 })
  let menu = NSMenu()
  let snapshot = SurfaceSnapshot.decode(json: contractSample)!
  content.fill(menu, snapshot: snapshot, appName: "Starter")

  let titles = menu.items.map(\.title)
  expect(
    titles == ["Starter, Build running", "", "Pricing", "", "Open Starter", "Quit Starter"],
    "the menu's items, in order")
  expect(menu.items[0].view is SurfaceMenuHeaderView, "the header is the real header view")
  expect((menu.items[0].view?.frame.height ?? 0) > 40, "the header has a height")

  menu.performActionForItem(at: 2)
  expect(routes == ["/pricing"], "choosing an action opens its route")
  menu.performActionForItem(at: 4)
  expect(opened == 1 && routes.count == 1, "Open brings the app forward without a route")
  menu.performActionForItem(at: 5)
  expect(quit == 1, "Quit quits")
  expect(menu.items[5].keyEquivalent == "q", "Quit has its usual key")

  content.fill(menu, snapshot: .fallback, appName: "Starter")
  expect(
    menu.items.map(\.title).dropFirst() == ["", "Open Starter", "Quit Starter"],
    "no actions leaves no empty section")

  let icon = SurfaceMenuBarIcon.image(appName: "Starter")
  expect(icon.isTemplate && icon.size == NSSize(width: 18, height: 18), "the icon is an 18pt template")
}

exit(MainActor.assumeIsolated { run() })
