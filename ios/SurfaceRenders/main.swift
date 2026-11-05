// Renders every native surface to PNG on an iOS simulator, with the real views and fonts, so they
// can be checked without gestures. Not part of the Xcode project. Run it with render.sh.
//
// `spawn` has no WidgetKit host, so this draws what the views draw, not what the system composites.
// The lock screen's one-tone treatment and the Dynamic Island's exact region layout come from the
// system; check those on a simulator or device as well.

import CoreText
import SwiftUI
import UIKit

private struct Scenario {
  let name: String
  let snapshot: SurfaceSnapshot
}

private func sample(
  title: String = "Starter",
  subtitle: String,
  value: String? = nil,
  valueLabel: String? = nil,
  progress: Double? = nil,
  status: SurfaceStatus,
  actions: [SurfaceAction] = [
    SurfaceAction(label: "Home", route: "/"),
    SurfaceAction(label: "Pricing", route: "/pricing"),
    SurfaceAction(label: "Settings", route: "/settings"),
  ]
) -> SurfaceSnapshot {
  SurfaceSnapshot(
    schema: 1, title: title, subtitle: subtitle, value: value, valueLabel: valueLabel,
    progress: progress, status: status, updatedAt: "2026-11-05T01:00:00.000Z", route: "/",
    actions: actions)
}

private let scenarios = [
  Scenario(
    name: "running",
    snapshot: sample(
      subtitle: "Build running", value: "72%", valueLabel: "Complete", progress: 0.72,
      status: .active)),
  Scenario(
    name: "finished",
    snapshot: sample(
      subtitle: "Build finished", value: "100%", valueLabel: "Complete", progress: 1,
      status: .success)),
  Scenario(
    name: "failed",
    snapshot: sample(
      subtitle: "Build failed", value: "41%", valueLabel: "Complete", progress: 0.41,
      status: .failure)),
  Scenario(
    name: "figure",
    snapshot: sample(
      title: "Downloads", subtitle: "Up 124 today", value: "6,482", valueLabel: "this week",
      status: .success)),
  Scenario(
    name: "warning",
    snapshot: sample(subtitle: "Payment needs attention", status: .warning)),
  Scenario(
    name: "published",
    snapshot: sample(subtitle: "A clean place to start your next app.", status: .idle)),
  Scenario(name: "fallback", snapshot: .fallback),
  Scenario(
    name: "long",
    snapshot: sample(
      title: "Nightly production deployment", subtitle: "Waiting for the database migration to finish",
      value: "1,234,567", valueLabel: "Records processed", progress: 0.33, status: .active)),
  Scenario(
    name: "arabic",
    snapshot: sample(
      title: "ستارتر", subtitle: "البناء قيد التشغيل", value: "72%", valueLabel: "مكتمل",
      progress: 0.72, status: .active,
      actions: [
        SurfaceAction(label: "الرئيسية", route: "/"),
        SurfaceAction(label: "الأسعار", route: "/pricing"),
      ])),
]

// MARK: Frames that stand in for what the system supplies

/// A home screen tile: the widget's page, clipped to the corner radius the system uses.
private struct HomeTile<Content: View>: View {
  let size: CGSize
  let content: Content
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    content
      .frame(width: size.width, height: size.height)
      .background(SurfacePalette.of(scheme).page)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
  }
}

/// A wallpaper for lock screen surfaces. Accessory views draw hierarchical styles on it.
private struct Wallpaper<Content: View>: View {
  let content: Content
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    content
      .padding(12)
      .background(
        LinearGradient(
          colors: scheme == .dark
            ? [Color(white: 0.16), Color(white: 0.05)]
            : [Color(white: 0.93), Color(white: 0.8)],
          startPoint: .top, endPoint: .bottom)
      )
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

private let black = Color.black

/// The island around the camera, with its compact regions on either side.
private struct IslandCompact: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    HStack(spacing: 0) {
      LiveCompactLeadingView(snapshot: snapshot).padding(.leading, 12)
      Spacer(minLength: 126)
      LiveCompactTrailingView(snapshot: snapshot).padding(.trailing, 14)
    }
    .frame(width: 250, height: 37)
    .background(black)
    .clipShape(Capsule())
  }
}

private struct IslandMinimal: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    LiveMinimalView(snapshot: snapshot)
      .frame(width: 37, height: 37)
      .background(black)
      .clipShape(Circle())
  }
}

private struct IslandExpanded: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    VStack(spacing: 6) {
      HStack(alignment: .top, spacing: 8) {
        LiveExpandedLeadingView(snapshot: snapshot)
        LiveExpandedCenterView(snapshot: snapshot)
        LiveExpandedTrailingView(snapshot: snapshot)
      }
      LiveExpandedBottomView(snapshot: snapshot)
    }
    .padding(14)
    .frame(width: 371)
    .background(black)
    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    .environment(\.colorScheme, .dark)
  }
}

// MARK: Families

private struct Family {
  let name: String
  let view: (SurfaceSnapshot) -> AnyView
}

private let small = CGSize(width: 158, height: 158)
private let medium = CGSize(width: 338, height: 158)

private let families: [Family] = [
  Family(name: "systemSmall") {
    AnyView(HomeTile(size: small, content: HomeSmallView(snapshot: $0)))
  },
  Family(name: "systemMedium") {
    AnyView(HomeTile(size: medium, content: HomeMediumView(snapshot: $0)))
  },
  Family(name: "accessoryCircular") {
    AnyView(Wallpaper(content: LockCircularView(snapshot: $0).frame(width: 72, height: 72)))
  },
  Family(name: "accessoryRectangular") {
    AnyView(Wallpaper(content: LockRectangularView(snapshot: $0).frame(width: 172, height: 76)))
  },
  Family(name: "accessoryInline") {
    AnyView(Wallpaper(content: LockInlineView(snapshot: $0).frame(width: 234, height: 22)))
  },
  Family(name: "liveBanner") { snapshot in
    AnyView(
      Wallpaper(
        content: LiveBannerView(snapshot: snapshot)
          .frame(width: 364)
          .background(SurfacePalette.adaptivePage)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))))
  },
  Family(name: "islandCompact") { AnyView(Wallpaper(content: IslandCompact(snapshot: $0))) },
  Family(name: "islandMinimal") { AnyView(Wallpaper(content: IslandMinimal(snapshot: $0))) },
  Family(name: "islandExpanded") { AnyView(Wallpaper(content: IslandExpanded(snapshot: $0))) },
]

// MARK: Rendering

private func registerFonts(in directory: String) {
  for weight in ["400", "500", "600"] {
    let path = "\(directory)/onest-latin-\(weight)-normal.ttf"
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: path) as CFURL, .process, &error) {
      print("font not registered: \(path)")
    }
  }
}

@MainActor
private func write<V: View>(_ view: V, scheme: ColorScheme, to path: String, background: Color? = nil) {
  // UIColor-backed colors resolve against the trait collection in effect, not the environment.
  let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
  UITraitCollection.current = UITraitCollection(userInterfaceStyle: style)
  let renderer = ImageRenderer(
    content: view
      .environment(\.colorScheme, scheme)
      .background(background ?? Color.clear))
  renderer.scale = 3
  renderer.isOpaque = background != nil
  guard let data = renderer.uiImage?.pngData() else {
    print("render failed: \(path)")
    return
  }
  try? data.write(to: URL(fileURLWithPath: path))
}

/// One image per family, in one appearance, with every scenario, for review at a glance.
private struct Sheet: View {
  let family: Family
  let scheme: ColorScheme

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(sheetColumn(family)), spacing: 24), count: sheetColumns(family)), alignment: .leading, spacing: 20) {
      ForEach(scenarios, id: \.name) { scenario in
        VStack(alignment: .leading, spacing: 6) {
          Text("\(family.name) · \(scenario.name) · \(scheme == .dark ? "dark" : "light")")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(scheme == .dark ? Color(white: 0.55) : Color(white: 0.45))
          family.view(scenario.snapshot)
            .environment(\.layoutDirection, scenario.name == "arabic" ? .rightToLeft : .leftToRight)
        }
      }
    }
    .padding(24)
  }
}

private func sheetColumn(_ family: Family) -> CGFloat {
  switch family.name {
  case "systemSmall", "accessoryCircular", "islandMinimal": return 170
  case "accessoryRectangular", "accessoryInline", "islandCompact": return 280
  default: return 400
  }
}

private func sheetColumns(_ family: Family) -> Int {
  sheetColumn(family) == 170 ? 5 : sheetColumn(family) == 280 ? 3 : 3
}

@main
struct SurfaceRenders {
  static func main() {
    let arguments = CommandLine.arguments
    guard arguments.count == 3 else {
      print("usage: render <output directory> <fonts directory>")
      exit(2)
    }
    let output = arguments[1]
    registerFonts(in: arguments[2])
    try? FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
    MainActor.assumeIsolated {
      for scheme in [ColorScheme.dark, .light] {
        let schemeName = scheme == .dark ? "dark" : "light"
        let page = scheme == .dark ? Color(white: 0.09) : Color(white: 0.96)
        for family in families {
          for scenario in scenarios {
            write(
              family.view(scenario.snapshot)
                .environment(
                  \.layoutDirection, scenario.name == "arabic" ? .rightToLeft : .leftToRight),
              scheme: scheme,
              to: "\(output)/\(family.name)-\(scenario.name)-\(schemeName).png")
          }
          write(
            Sheet(family: family, scheme: scheme),
            scheme: scheme,
            to: "\(output)/sheet-\(family.name)-\(schemeName).png",
            background: page)
        }
      }
    }
    print("rendered \(families.count) families, \(scenarios.count) scenarios to \(output)")
  }
}
