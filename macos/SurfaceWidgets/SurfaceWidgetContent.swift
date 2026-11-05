import SwiftUI
import WidgetKit

/// What a widget draws. Follows the brand's live widget: a titled card, one big figure or a ring
/// gauge, and the words under it. All of it takes plain values, so it renders headlessly.
struct SurfaceWidgetContent: View {
  let snapshot: SurfaceSnapshot
  let family: WidgetFamily
  let palette: SurfacePalette

  var body: some View {
    switch family {
    case .systemMedium: medium
    case .systemLarge: large
    default: small
    }
  }

  // MARK: Families

  private var small: some View {
    VStack(spacing: 0) {
      switch hero {
      case .gauge(let progress):
        titleRow(size: 12)
        Spacer(minLength: 6)
        SurfaceGauge(
          progress: progress,
          tint: gaugeTint,
          highlight: gaugeHighlight,
          palette: palette,
          diameter: 88,
          value: snapshot.value,
          valueSize: 19,
          label: nil
        )
        Spacer(minLength: 6)
        subtitle(size: 11, lines: 1).frame(maxWidth: .infinity)
      case .figure(let value):
        titleRow(size: 12)
        Spacer(minLength: 4)
        figure(value, size: 38, labelSize: 12)
        Spacer(minLength: 4)
        subtitle(size: 11, lines: 1).frame(maxWidth: .infinity, alignment: .leading)
      case .wordmark:
        wordmarkLead(size: 12, lines: 3)
        Spacer(minLength: 4)
        SurfaceWordmark(text: snapshot.title, size: 32, palette: palette)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var medium: some View {
    HStack(alignment: .center, spacing: 18) {
      switch hero {
      case .gauge(let progress):
        SurfaceGauge(
          progress: progress,
          tint: gaugeTint,
          highlight: gaugeHighlight,
          palette: palette,
          diameter: 122,
          value: snapshot.value,
          valueSize: 28,
          label: snapshot.valueLabel,
          labelSize: 10
        )
        details
      case .figure(let value):
        figure(value, size: 44, labelSize: 13)
          .frame(maxWidth: .infinity, alignment: .leading)
        details
      case .wordmark:
        VStack(alignment: .leading, spacing: 0) {
          wordmarkLead(size: 13, lines: 3)
          Spacer(minLength: 4)
          SurfaceWordmark(
            text: snapshot.title,
            size: snapshot.actions.isEmpty ? 56 : 30,
            palette: palette
          )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        if !snapshot.actions.isEmpty {
          actionRows(limit: 4, size: 12, rowHeight: 26)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var large: some View {
    Group {
      switch hero {
      case .gauge(let progress):
        largeCard(actionLimit: 3) {
          largeHeader
          Spacer(minLength: 6)
          SurfaceGauge(
            progress: progress,
            tint: gaugeTint,
            highlight: gaugeHighlight,
            palette: palette,
            diameter: 140,
            value: snapshot.value,
            valueSize: 34,
            label: snapshot.valueLabel,
            labelSize: 11
          )
          Spacer(minLength: 6)
          Text(snapshot.subtitle)
            .font(palette.heading(15))
            .foregroundColor(palette.text)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
        }
      case .figure(let value):
        largeCard(actionLimit: 4) {
          largeHeader
          Spacer(minLength: 6)
          figure(value, size: 64, labelSize: 14)
          Spacer(minLength: 6)
          subtitle(size: 13, lines: 2).frame(maxWidth: .infinity, alignment: .leading)
        }
      case .wordmark:
        // The brand signs off with its giant wordmark, so this card ends on it, with no footer.
        VStack(spacing: 0) {
          wordmarkLead(size: 15, lines: 3)
          Spacer(minLength: 8)
          if !snapshot.actions.isEmpty {
            actionRows(limit: 4, size: 12.5, rowHeight: 28)
          }
          SurfaceWordmark(text: snapshot.title, size: 72, palette: palette)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
        }
        .padding(18)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func largeCard<Content: View>(
    actionLimit: Int,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(spacing: 0) {
      VStack(spacing: 0) {
        content()
        if !snapshot.actions.isEmpty {
          actionRows(limit: actionLimit, size: 12.5, rowHeight: 26)
            .padding(.top, 10)
        }
      }
      .padding(.horizontal, 18)
      largeFooter
    }
    .padding(.top, 16)
  }

  // MARK: Pieces

  private enum Hero {
    case gauge(Double)
    case figure(String)
    case wordmark
  }

  private var hero: Hero {
    if let progress = snapshot.progress { return .gauge(progress) }
    if let value = snapshot.value { return .figure(value) }
    return .wordmark
  }

  private var marker: some View {
    SurfaceMarker(status: snapshot.status, palette: palette, size: 8)
  }

  /// The brand's gauge is copper, so the arc warms toward its end while the work is under way.
  /// Any other status takes that status's one color.
  private var gaugeTint: Color { palette.color(for: snapshot.status == .idle ? .active : snapshot.status) }
  private var gaugeHighlight: Color {
    snapshot.status == .active || snapshot.status == .idle ? palette.accentHighlight : gaugeTint
  }

  private func titleRow(size: CGFloat) -> some View {
    HStack(spacing: 6) {
      Text(snapshot.title)
        .font(palette.heading(size))
        .foregroundColor(palette.text)
        .lineLimit(1)
      Spacer(minLength: 4)
      marker
    }
  }

  /// The words above a wordmark, and the state when there is one to show.
  private func wordmarkLead(size: CGFloat, lines: Int) -> some View {
    HStack(alignment: .top, spacing: 6) {
      subtitle(size: size, lines: lines)
        .frame(maxWidth: .infinity, alignment: .leading)
      if snapshot.status != .idle { marker }
    }
  }

  private func subtitle(size: CGFloat, lines: Int) -> some View {
    Text(snapshot.subtitle)
      .font(palette.body(size))
      .foregroundColor(palette.muted)
      .lineLimit(lines)
      .truncationMode(.tail)
  }

  private func figure(_ value: String, size: CGFloat, labelSize: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: size * 0.14) {
      Text(value)
        .font(palette.heading(size))
        .tracking(surfaceFigureTracking(value, size: size))
        .foregroundColor(palette.text)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .fixedSize(horizontal: false, vertical: true)
      if let label = snapshot.valueLabel {
        Text(label)
          .font(palette.body(labelSize))
          .foregroundColor(palette.muted)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .layoutPriority(1)
  }

  /// The right-hand column of the medium widget.
  private var details: some View {
    VStack(alignment: .leading, spacing: 0) {
      titleRow(size: 12)
      Text(snapshot.subtitle)
        .font(palette.heading(14))
        .foregroundColor(palette.text)
        .lineLimit(2)
        .padding(.top, 6)
      Spacer(minLength: 6)
      if !snapshot.actions.isEmpty {
        actionRows(limit: 3, size: 11.5, rowHeight: 22)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func actionRows(limit: Int, size: CGFloat, rowHeight: CGFloat) -> some View {
    VStack(spacing: 0) {
      ForEach(Array(snapshot.actions.prefix(limit).enumerated()), id: \.offset) { index, action in
        if index > 0 { hairline }
        Link(destination: SurfaceLink.url(route: action.route)) {
          HStack(spacing: 6) {
            Text(action.label)
              .font(palette.body(size))
              .foregroundColor(palette.text)
              .lineLimit(1)
            Spacer(minLength: 4)
            SurfaceArrowUpRight()
              .stroke(
                palette.muted,
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
              )
              .frame(width: 10, height: 10)
          }
          .frame(height: rowHeight)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var hairline: some View {
    Rectangle().fill(palette.line).frame(height: 1)
  }

  private var largeHeader: some View {
    HStack {
      Text(snapshot.title)
        .font(palette.heading(14))
        .foregroundColor(palette.text)
        .lineLimit(1)
      Spacer(minLength: 0)
    }
  }

  /// As on the brand's card: a quiet line under everything, with the state at its right.
  private var largeFooter: some View {
    VStack(spacing: 0) {
      hairline.padding(.top, 8)
      HStack(spacing: 6) {
        if let updatedAt = snapshot.updatedAt {
          Text(updatedAt, style: .time)
            .font(palette.body(11))
            .foregroundColor(palette.muted)
        }
        Spacer(minLength: 4)
        marker
      }
      .padding(.horizontal, 18)
      .frame(height: 30)
    }
  }
}

/// The brand's ring gauge from the live widget: a dotted outer ring, a heavy track with the
/// progress on it, and a thin inner ring holding the figure. Sizes follow the brand's 180 grid.
struct SurfaceGauge: View {
  let progress: Double
  let tint: Color
  let highlight: Color
  let palette: SurfacePalette
  let diameter: CGFloat
  let value: String?
  let valueSize: CGFloat
  let label: String?
  var labelSize: CGFloat = 10

  var body: some View {
    let unit = diameter / 156
    ZStack {
      Circle()
        .stroke(palette.line, style: StrokeStyle(lineWidth: max(1, unit), dash: [1, 7 * unit]))
        .frame(width: 154 * unit, height: 154 * unit)
      Circle()
        .stroke(palette.line, lineWidth: 7 * unit)
        .frame(width: 124 * unit, height: 124 * unit)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [tint, tint, highlight]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(max(1, 360 * progress))
          ),
          style: StrokeStyle(lineWidth: 7 * unit, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .frame(width: 124 * unit, height: 124 * unit)
      Circle()
        .stroke(palette.line, lineWidth: 1)
        .frame(width: 96 * unit, height: 96 * unit)
      VStack(spacing: labelSize * 0.25) {
        if let value = value {
          Text(value)
            .font(palette.heading(valueSize))
            .tracking(surfaceFigureTracking(value, size: valueSize))
            .foregroundColor(palette.text)
            .lineLimit(1)
            .minimumScaleFactor(0.3)
        }
        if let label = label {
          Text(label)
            .font(palette.body(labelSize))
            .foregroundColor(palette.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
      }
      .frame(width: 80 * unit)
    }
    .frame(width: diameter, height: diameter)
  }
}

/// Lucide's `arrow-up-right`, the brand's "go" arrow.
struct SurfaceArrowUpRight: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY - rect.height * 0.1))
    path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.minY + rect.height * 0.1))
    path.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.1))
    path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.minY + rect.height * 0.1))
    path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY - rect.height * 0.25))
    return path
  }
}
