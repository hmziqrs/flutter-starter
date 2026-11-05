import AppKit
import CoreText
import SwiftUI

/// The contract's colors (docs/native_surfaces.md, "Look").
struct SurfacePalette {
  let page: Color
  let text: Color
  let muted: Color
  let line: Color
  let accent: Color
  let accentHighlight: Color
  let success: Color
  let warning: Color
  let failure: Color
  let wordmarkSquare: Color
  /// Type in light mode sits one step heavier, so black on white reads as solid (BRAND.md s5).
  let headingFontName: String

  static let dark = SurfacePalette(
    page: Color(hex: 0x0A0A0A),
    text: Color(hex: 0xFAFAFA),
    muted: Color(hex: 0xA1A1A1),
    line: Color(hex: 0x262626),
    accent: Color(hex: 0xF38230),
    accentHighlight: Color(hex: 0xFFC49A),
    success: Color(hex: 0x4ADE80),
    warning: Color(hex: 0xFACC15),
    failure: Color(hex: 0xF87171),
    wordmarkSquare: Color(hex: 0xF38230),
    headingFontName: SurfaceFont.medium
  )

  static let light = SurfacePalette(
    page: Color(hex: 0xFFFFFF),
    text: Color(hex: 0x0A0A0A),
    muted: Color(hex: 0x737373),
    line: Color(hex: 0xE5E5E5),
    accent: Color(hex: 0xAA530A),
    accentHighlight: Color(hex: 0xD97F33),
    success: Color(hex: 0x15803D),
    warning: Color(hex: 0xA16207),
    failure: Color(hex: 0xB91C1C),
    wordmarkSquare: Color(hex: 0xF38230),
    headingFontName: SurfaceFont.semiBold
  )

  /// For a desktop widget the system dims while another app is in front. It desaturates what we
  /// draw, so fixed colors would lose their contrast. System styles keep it.
  static let vibrant = SurfacePalette(
    page: .clear,
    text: .primary,
    muted: .secondary,
    line: Color.primary.opacity(0.2),
    accent: .primary,
    accentHighlight: .primary,
    success: .primary,
    warning: .primary,
    failure: .primary,
    wordmarkSquare: .primary,
    headingFontName: SurfaceFont.medium
  )

  static func forScheme(_ scheme: ColorScheme) -> SurfacePalette {
    scheme == .dark ? dark : light
  }

  func color(for status: SurfaceStatus) -> Color {
    switch status {
    case .idle: return muted
    case .active: return accent
    case .success: return success
    case .warning: return warning
    case .failure: return failure
    }
  }

  func heading(_ size: CGFloat) -> Font { .custom(headingFontName, fixedSize: size) }
  func body(_ size: CGFloat) -> Font { .custom(SurfaceFont.regular, fixedSize: size) }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255
    )
  }
}

/// The bundled Onest, registered for this process. Text falls back to the system font if a file
/// is missing, so a font problem never hides content.
enum SurfaceFont {
  static let regular = "Onest-Regular"
  static let medium = "Onest-Medium"
  static let semiBold = "Onest-SemiBold"
  private static let files = [
    "onest-latin-400-normal", "onest-latin-500-normal", "onest-latin-600-normal",
  ]

  private static let registerOnce: Void = {
    register(urls: files.compactMap { Bundle.main.url(forResource: $0, withExtension: "ttf") })
  }()

  static func registerBundled() {
    _ = registerOnce
  }

  static func register(urls: [URL]) {
    for url in urls {
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
  }
}

/// The brand's tight figures. Tracking is a fixed length that does not shrink with the text, so a
/// figure long enough to be scaled down to fit goes without it rather than colliding with itself.
func surfaceFigureTracking(_ value: String, size: CGFloat) -> CGFloat {
  value.count > 6 ? 0 : -0.035 * size
}

/// The brand's status bullet: a hollow ring, filled when something is on or done (BRAND.md s7).
struct SurfaceMarker: View {
  let status: SurfaceStatus
  let palette: SurfacePalette
  var size: CGFloat = 9

  var body: some View {
    let color = palette.color(for: status)
    ZStack {
      if status != .idle { Circle().fill(color) }
      Circle().strokeBorder(color, lineWidth: 1.75)
    }
    .frame(width: size, height: size)
  }
}

/// The name ending in the orange square, which keeps its bright orange in both modes.
struct SurfaceWordmark: View {
  let text: String
  let size: CGFloat
  let palette: SurfacePalette

  var body: some View {
    HStack(alignment: .lastTextBaseline, spacing: size * 0.07) {
      Text(text)
        .font(.custom(SurfaceFont.semiBold, fixedSize: size))
        .tracking(-0.02 * size)
        .foregroundColor(palette.text)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
      Rectangle()
        .fill(palette.wordmarkSquare)
        .frame(width: size * 0.3, height: size * 0.3)
    }
  }
}
