import SwiftUI
import WidgetKit

// The lock screen draws these in one tone over the wallpaper, whatever color they ask for. So they
// use hierarchical styles, and carry status as a glyph.

/// `accessoryCircular`: the gauge reduced to its ring, or the app's mark when nothing is measured.
@available(iOS 16.0, *)
struct LockCircularView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    ZStack {
      if let progress = snapshot.clampedProgress {
        SurfaceRing(
          progress: progress,
          lineWidth: 5,
          track: AnyShapeStyle(.tertiary),
          arc: AnyShapeStyle(.primary)
        )
        center
          .padding(9)
      } else {
        AccessoryWidgetBackground()
        center
          .padding(7)
      }
    }
    .widgetAccentable()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(snapshot.accessibilitySummary)
  }

  @ViewBuilder
  private var center: some View {
    if let value = snapshot.value {
      VStack(spacing: 0) {
        Text(value)
          .font(SurfaceFont.onest(.medium, 17))
          .tracking(17 * -0.04)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
        if snapshot.clampedProgress == nil, let label = snapshot.valueLabel {
          Text(label)
            .font(SurfaceFont.onest(.regular, 9))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
      }
    } else if let symbol = snapshot.status.symbol, snapshot.status != .active {
      Image(systemName: symbol).font(.system(size: 20, weight: .medium))
    } else {
      mark
    }
  }

  /// The brand's mark: the name's first letter and the square.
  private var mark: some View {
    HStack(alignment: .firstTextBaseline, spacing: 26 * 0.07) {
      Text(String(snapshot.title.prefix(1)))
        .font(SurfaceFont.onest(.semibold, 26))
      Rectangle()
        .frame(width: 26 * 0.26, height: 26 * 0.26)
    }
  }
}

/// `accessoryRectangular`: name and figure on one line, the state under it, then the bar.
@available(iOS 16.0, *)
struct LockRectangularView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 4) {
        if let symbol = snapshot.status.symbol {
          Image(systemName: symbol)
            .font(.system(size: 10, weight: .semibold))
            .widgetAccentable()
        }
        Text(snapshot.title)
          .font(SurfaceFont.onest(.medium, 14))
          .lineLimit(1)
          .widgetAccentable()
        Spacer(minLength: 2)
        if let value = snapshot.value {
          Text(value)
            .font(SurfaceFont.onest(.medium, 14))
            .tracking(14 * -0.02)
            .lineLimit(1)
            .layoutPriority(1)
        }
      }
      Text(detail)
        .font(SurfaceFont.onest(.regular, 13))
        .foregroundStyle(.secondary)
        .lineLimit(snapshot.clampedProgress == nil ? 2 : 1)
      if let progress = snapshot.clampedProgress {
        Spacer(minLength: 0)
        LockProgressBar(progress: progress)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(snapshot.accessibilitySummary)
  }

  /// With no bar there is room to say what the figure is.
  private var detail: String {
    if snapshot.clampedProgress == nil, let label = snapshot.valueLabel {
      return "\(label) · \(snapshot.subtitle)"
    }
    return snapshot.subtitle
  }
}

@available(iOS 16.0, *)
private struct LockProgressBar: View {
  let progress: Double

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(.tertiary)
        Capsule()
          .fill(.primary)
          .frame(width: max(5, geometry.size.width * CGFloat(progress)))
          .opacity(progress > 0 ? 1 : 0)
          .widgetAccentable()
      }
    }
    .frame(height: 5)
  }
}

/// `accessoryInline`: one line of system text, which is all the system allows here. It says as
/// much as fits, because this slot's width changes with the date beside it.
@available(iOS 16.0, *)
struct LockInlineView: View {
  let snapshot: SurfaceSnapshot

  var body: some View {
    ViewThatFits {
      ForEach(lines, id: \.self) { line in
        if let symbol = snapshot.status.symbol {
          Label(line, systemImage: symbol)
        } else {
          Text(line)
        }
      }
    }
    .accessibilityLabel(snapshot.accessibilitySummary)
  }

  private var lines: [String] {
    guard let value = snapshot.value else { return [snapshot.subtitle, snapshot.title] }
    return ["\(value) · \(snapshot.subtitle)", "\(value) · \(snapshot.title)", value]
  }
}
