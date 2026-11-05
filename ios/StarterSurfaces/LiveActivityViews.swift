import SwiftUI

// The Dynamic Island is always black, so its views use the dark palette in both appearances.

/// The lock screen banner, the brand's activity tile: gauge on one side, words and rows on the
/// other. The system caps this at 160 points tall.
struct LiveBannerView: View {
  let snapshot: SurfaceSnapshot
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = SurfacePalette.of(scheme)
    VStack(alignment: .leading, spacing: 10) {
      SurfaceHeader(snapshot: snapshot, showsTime: true)
      HStack(alignment: .center, spacing: 16) {
        if snapshot.clampedProgress != nil {
          SurfaceGauge(snapshot: snapshot)
            .frame(width: 92, height: 92)
        } else if let value = snapshot.value {
          VStack(alignment: .leading, spacing: 4) {
            Text(value)
              .font(SurfaceFont.onest(.medium, 38))
              .tracking(38 * -0.05)
              .foregroundStyle(palette.text)
              .lineLimit(1)
              .minimumScaleFactor(0.5)
            if let label = snapshot.valueLabel {
              Text(label)
                .font(SurfaceFont.onest(.regular, 12))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
            }
          }
        }
        VStack(alignment: .leading, spacing: 8) {
          Text(snapshot.subtitle)
            .font(SurfaceFont.onest(.medium, 16))
            .foregroundStyle(palette.text)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
          SurfaceActionRows(actions: snapshot.actions, limit: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(14)
    // The system's background tint came out pure black on iOS 27, so the page is painted here too.
    .background(palette.page)
  }
}

/// The status glyph in its color, for when there is no ring to carry the status.
private struct LiveStatusGlyph: View {
  let status: SurfaceStatus
  let size: CGFloat

  var body: some View {
    if let symbol = status.symbol, status != .active, let color = SurfacePalette.dark.dot(for: status) {
      Image(systemName: symbol)
        .font(.system(size: size, weight: .semibold))
        .foregroundStyle(color)
    }
  }
}

/// The app's square, the same in every appearance.
private struct LiveSquare: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(SurfacePalette.dark.accent)
      .frame(width: size, height: size)
  }
}

/// The progress ring on the island's track, in the status color.
private struct LiveRing: View {
  let progress: Double
  let status: SurfaceStatus
  let size: CGFloat

  var body: some View {
    let palette = SurfacePalette.dark
    SurfaceRing(
      progress: progress,
      lineWidth: max(2.5, size * 0.13),
      track: palette.line,
      arc: palette.gaugeStyle(for: status)
    )
    .frame(width: size, height: size)
  }
}

/// Compact, beside the camera on the leading side: progress if there is any, otherwise the square.
struct LiveCompactLeadingView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    if let progress = snapshot.clampedProgress {
      LiveRing(progress: progress, status: snapshot.status, size: 20)
    } else {
      LiveSquare(size: 9).frame(width: 20, height: 20)
    }
  }
}

/// Compact, beside the camera on the trailing side: the figure, otherwise the status.
struct LiveCompactTrailingView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    if let value = snapshot.value {
      Text(value)
        .font(SurfaceFont.onest(.medium, 14))
        .tracking(14 * -0.02)
        .foregroundStyle(SurfacePalette.dark.text)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: 48)
    } else {
      LiveStatusGlyph(status: snapshot.status, size: 13)
    }
  }
}

/// Minimal, when another activity shares the island: one mark that says the most it can.
struct LiveMinimalView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    if let progress = snapshot.clampedProgress {
      LiveRing(progress: progress, status: snapshot.status, size: 22)
    } else if snapshot.status == .idle || snapshot.status == .active {
      LiveSquare(size: 9)
    } else {
      LiveStatusGlyph(status: snapshot.status, size: 14)
    }
  }
}

/// Expanded, leading region: the ring, or an empty ring around the status when nothing is measured.
struct LiveExpandedLeadingView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    ZStack {
      LiveRing(progress: snapshot.clampedProgress ?? 0, status: snapshot.status, size: 44)
      if snapshot.clampedProgress == nil {
        if snapshot.status == .idle || snapshot.status == .active {
          LiveSquare(size: 10)
        } else {
          LiveStatusGlyph(status: snapshot.status, size: 17)
        }
      }
    }
    .padding(.leading, 6)
    .padding(.top, 12)
  }
}

/// Expanded, center region.
struct LiveExpandedCenterView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    let palette = SurfacePalette.dark
    VStack(alignment: .leading, spacing: 2) {
      Text(snapshot.title)
        .font(SurfaceFont.onest(.regular, 12))
        .foregroundStyle(palette.muted)
        .lineLimit(1)
      Text(snapshot.subtitle)
        .font(SurfaceFont.onest(.medium, 15))
        .foregroundStyle(palette.text)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Expanded, trailing region.
struct LiveExpandedTrailingView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    let palette = SurfacePalette.dark
    VStack(alignment: .trailing, spacing: 2) {
      if let value = snapshot.value {
        Text(value)
          .font(SurfaceFont.onest(.medium, 22))
          .tracking(22 * -0.04)
          .foregroundStyle(palette.text)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }
      if let label = snapshot.valueLabel {
        Text(label)
          .font(SurfaceFont.onest(.regular, 10))
          .foregroundStyle(palette.muted)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .frame(minWidth: 60, maxWidth: 104, alignment: .trailing)
    .padding(.trailing, 6)
    .padding(.top, 12)
  }
}

/// Expanded, bottom region: the actions, side by side.
struct LiveExpandedBottomView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    let palette = SurfacePalette.dark
    if !snapshot.actions.isEmpty {
      HStack(spacing: 8) {
        ForEach(Array(snapshot.actions.prefix(3)), id: \.self) { action in
          if let url = SurfaceLink.url(route: action.route) {
            Link(destination: url) {
              Text(action.label)
                .font(SurfaceFont.onest(.medium, 12))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .overlay(Capsule().stroke(palette.line, lineWidth: 1))
            }
          }
        }
      }
      .padding(.horizontal, 6)
      .padding(.top, 4)
    }
  }
}
