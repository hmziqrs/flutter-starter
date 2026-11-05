import SwiftUI
import UIKit

extension Color {
  fileprivate init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1
    )
  }
}

/// The colors in docs/native_surfaces.md, for one appearance.
struct SurfacePalette {
  let page: Color
  let text: Color
  let muted: Color
  let line: Color
  let accent: Color
  /// The bright edge of the copper sweep on a running gauge.
  let accentHighlight: Color
  let success: Color
  let warning: Color
  let failure: Color

  static let dark = SurfacePalette(
    page: Color(hex: 0x0A0A0A),
    text: Color(hex: 0xFAFAFA),
    muted: Color(hex: 0xA1A1A1),
    line: Color(hex: 0x262626),
    accent: Color(hex: 0xF38230),
    accentHighlight: Color(hex: 0xFBC59C),
    success: Color(hex: 0x4ADE80),
    warning: Color(hex: 0xFACC15),
    failure: Color(hex: 0xF87171)
  )

  static let light = SurfacePalette(
    page: Color(hex: 0xFFFFFF),
    text: Color(hex: 0x0A0A0A),
    muted: Color(hex: 0x737373),
    line: Color(hex: 0xE5E5E5),
    accent: Color(hex: 0xAA530A),
    accentHighlight: Color(hex: 0xE08A3C),
    success: Color(hex: 0x15803D),
    warning: Color(hex: 0xA16207),
    failure: Color(hex: 0xB91C1C)
  )

  static func of(_ scheme: ColorScheme) -> SurfacePalette { scheme == .dark ? dark : light }

  /// A page color that follows the system, for APIs that take one color outside a view's
  /// environment, such as the Live Activity's background tint.
  static let adaptivePage = Color(
    UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark.page) : UIColor(light.page) })

  /// The color of a status dot. A running surface shows the brand's green "live" dot; its copper
  /// belongs to the gauge.
  func dot(for status: SurfaceStatus) -> Color? {
    switch status {
    case .idle: return nil
    case .active, .success: return success
    case .warning: return warning
    case .failure: return failure
    }
  }

  /// The filled part of a gauge or progress bar.
  func gaugeStyle(for status: SurfaceStatus) -> AnyShapeStyle {
    switch status {
    case .idle: return AnyShapeStyle(muted)
    case .active:
      return AnyShapeStyle(
        AngularGradient(colors: [accent, accentHighlight, accent], center: .center))
    case .success: return AnyShapeStyle(success)
    case .warning: return AnyShapeStyle(warning)
    case .failure: return AnyShapeStyle(failure)
    }
  }
}

enum SurfaceFont {
  enum Weight: String {
    case regular = "Onest-Regular"
    case medium = "Onest-Medium"
    case semibold = "Onest-SemiBold"
  }

  /// Onest, which the extension bundles. Its Latin subset falls back to the system font for other
  /// scripts, through the normal font cascade.
  static func onest(_ weight: Weight, _ size: CGFloat) -> Font { .custom(weight.rawValue, size: size) }
}

extension SurfaceStatus {
  /// A glyph for lock screen surfaces, which the system draws in one tone, so status cannot rely
  /// on color there. Lucide is not available to WidgetKit, so these are its closest SF Symbols.
  var symbol: String? {
    switch self {
    case .idle: return nil
    case .active: return "circle.dotted"
    case .success: return "checkmark"
    case .warning: return "exclamationmark"
    case .failure: return "xmark"
    }
  }
}

extension SurfaceSnapshot {
  /// A spoken summary. It joins Dart's strings, so it adds no text of its own.
  var accessibilitySummary: String {
    [title, subtitle, value, valueLabel].compactMap { $0 }.joined(separator: ", ")
  }

  /// Whether there is nothing to measure, which is when a surface leads with the name.
  var isPlain: Bool { clampedProgress == nil && value == nil }
}

/// The app's name in Onest 600, ending in the small orange square. BRAND.md section 7.
struct SurfaceWordmark: View {
  let title: String
  var size: CGFloat = 16
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: size * 0.07) {
      Text(title)
        .font(SurfaceFont.onest(.semibold, size))
        .tracking(size * -0.02)
        .foregroundStyle(SurfacePalette.of(scheme).text)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Rectangle()
        .fill(SurfacePalette.dark.accent)
        .frame(width: size * 0.36, height: size * 0.36)
    }
  }
}

/// The small dot beside a title. It stands in for the brand tile's "Live" badge, whose word the
/// snapshot does not carry.
struct SurfaceStatusDot: View {
  let status: SurfaceStatus
  var size: CGFloat = 6
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    if let color = SurfacePalette.of(scheme).dot(for: status) {
      Circle().fill(color).frame(width: size, height: size)
    }
  }
}

/// The title row of a tile: name on the leading side, dot and last update on the trailing side.
struct SurfaceHeader: View {
  let snapshot: SurfaceSnapshot
  var showsTime = false
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = SurfacePalette.of(scheme)
    HStack(spacing: 6) {
      Text(snapshot.title)
        .font(SurfaceFont.onest(.medium, 13))
        .foregroundStyle(palette.text)
        .lineLimit(1)
      Spacer(minLength: 4)
      if showsTime, let date = snapshot.updatedDate {
        Text(date, style: .time)
          .font(SurfaceFont.onest(.regular, 11))
          .foregroundStyle(palette.muted)
          .lineLimit(1)
      }
      SurfaceStatusDot(status: snapshot.status)
    }
  }
}

/// A tappable row, the same shape as the rows on the brand's activity tile.
struct SurfaceActionRows: View {
  let actions: [SurfaceAction]
  var limit = 3
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = SurfacePalette.of(scheme)
    VStack(spacing: 6) {
      ForEach(Array(actions.prefix(limit)), id: \.self) { action in
        if let url = SurfaceLink.url(route: action.route) {
          Link(destination: url) {
            HStack(spacing: 6) {
              Text(action.label)
                .font(SurfaceFont.onest(.regular, 12))
                .foregroundStyle(palette.text)
                .lineLimit(1)
              Spacer(minLength: 4)
              Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(palette.muted)
            }
          }
        }
      }
    }
  }
}
