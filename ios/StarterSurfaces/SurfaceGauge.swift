import SwiftUI
import WidgetKit

extension View {
  /// Marks a view for the accent tint on tinted home screens and the lock screen.
  @ViewBuilder
  func surfaceAccentable() -> some View {
    if #available(iOS 16.0, *) {
      widgetAccentable()
    } else {
      self
    }
  }
}

/// A progress arc on a track.
struct SurfaceRing<Track: ShapeStyle, Arc: ShapeStyle>: View {
  let progress: Double
  let lineWidth: CGFloat
  let track: Track
  let arc: Arc

  var body: some View {
    ZStack {
      Circle().stroke(track, lineWidth: lineWidth)
      if progress > 0 {
        Circle()
          .trim(from: 0, to: CGFloat(progress))
          .stroke(arc, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
          .rotationEffect(.degrees(-90))
          .surfaceAccentable()
      }
    }
    .padding(lineWidth / 2)
  }
}

/// The brand's build gauge: a dotted outer ring, a thick track with the progress on it, and a
/// hairline inner ring around the value. It keeps the proportions of the 180-unit drawing in
/// live-widget.svelte, cropped to the dotted ring so it fills the room a widget has.
struct SurfaceGauge: View {
  let snapshot: SurfaceSnapshot
  @Environment(\.colorScheme) private var scheme

  private static let drawing: CGFloat = 160

  var body: some View {
    GeometryReader { geometry in
      let side = min(geometry.size.width, geometry.size.height)
      let unit = side / Self.drawing
      let palette = SurfacePalette.of(scheme)
      ZStack {
        Circle()
          .stroke(
            palette.muted.opacity(0.55),
            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [0.1, max(3, 7 * unit)])
          )
          .frame(width: 154 * unit, height: 154 * unit)
        SurfaceRing(
          progress: snapshot.clampedProgress ?? 0,
          lineWidth: max(4, 7 * unit),
          track: palette.line,
          arc: palette.gaugeStyle(for: snapshot.status)
        )
        .frame(width: 131 * unit, height: 131 * unit)
        Circle()
          .stroke(palette.line, lineWidth: 1)
          .frame(width: 96 * unit, height: 96 * unit)
        label(unit: unit, palette: palette)
          .frame(width: 88 * unit)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
  }

  @ViewBuilder
  private func label(unit: CGFloat, palette: SurfacePalette) -> some View {
    VStack(spacing: 2 * unit) {
      if let value = snapshot.value {
        Text(value)
          .font(SurfaceFont.onest(.medium, 30 * unit))
          .tracking(30 * unit * -0.05)
          .foregroundStyle(palette.text)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
      }
      if let label = snapshot.valueLabel {
        Text(label)
          .font(SurfaceFont.onest(.regular, max(9, 12 * unit)))
          .foregroundStyle(palette.muted)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
    }
  }
}
