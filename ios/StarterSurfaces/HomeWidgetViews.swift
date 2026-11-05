import SwiftUI

/// The big figure and its caption, the "downloads" tile's lead.
private struct SurfaceFigure: View {
  let value: String
  let label: String?
  var size: CGFloat = 38
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = SurfacePalette.of(scheme)
    VStack(alignment: .leading, spacing: 4) {
      Text(value)
        .font(SurfaceFont.onest(.medium, size))
        .tracking(size * -0.05)
        .foregroundStyle(palette.text)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
      if let label = label {
        Text(label)
          .font(SurfaceFont.onest(.regular, 12))
          .foregroundStyle(palette.muted)
          .lineLimit(1)
      }
    }
  }
}

/// `systemSmall`. It leads with whichever the snapshot has: progress, a figure, or just words.
struct HomeSmallView: View {
  let snapshot: SurfaceSnapshot
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = SurfacePalette.of(scheme)
    Group {
      if snapshot.clampedProgress != nil {
        VStack(spacing: 4) {
          SurfaceHeader(snapshot: snapshot)
          SurfaceGauge(snapshot: snapshot)
            .frame(maxHeight: .infinity)
          Text(snapshot.subtitle)
            .font(SurfaceFont.onest(.regular, 12))
            .foregroundStyle(palette.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
      } else if let value = snapshot.value {
        VStack(alignment: .leading, spacing: 0) {
          SurfaceHeader(snapshot: snapshot)
          Spacer(minLength: 4)
          SurfaceFigure(value: value, label: snapshot.valueLabel)
          Text(snapshot.subtitle)
            .font(SurfaceFont.onest(.regular, 12))
            .foregroundStyle(palette.muted)
            .lineLimit(2)
            .padding(.top, 8)
        }
      } else {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            SurfaceWordmark(title: snapshot.title, size: 15)
            Spacer(minLength: 4)
            SurfaceStatusDot(status: snapshot.status)
          }
          Spacer(minLength: 4)
          Text(snapshot.subtitle)
            .font(SurfaceFont.onest(.medium, 15))
            .foregroundStyle(palette.text)
            .lineLimit(4)
            .minimumScaleFactor(0.8)
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

/// `systemMedium`. The brand's activity tile: the lead on one side, words and rows on the other.
struct HomeMediumView: View {
  let snapshot: SurfaceSnapshot
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = SurfacePalette.of(scheme)
    Group {
      if snapshot.clampedProgress != nil {
        HStack(spacing: 16) {
          SurfaceGauge(snapshot: snapshot)
            .frame(maxHeight: .infinity)
          VStack(alignment: .leading, spacing: 0) {
            SurfaceHeader(snapshot: snapshot, showsTime: true)
            subtitle(palette).padding(.top, 8)
            Spacer(minLength: 6)
            SurfaceActionRows(actions: snapshot.actions)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      } else if let value = snapshot.value {
        VStack(spacing: 0) {
          SurfaceHeader(snapshot: snapshot, showsTime: true)
          HStack(alignment: .bottom, spacing: 16) {
            SurfaceFigure(value: value, label: snapshot.valueLabel, size: 44)
              .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 8) {
              Text(snapshot.subtitle)
                .font(SurfaceFont.onest(.regular, 12))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
              SurfaceActionRows(actions: snapshot.actions)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .frame(maxHeight: .infinity, alignment: .bottom)
        }
      } else {
        HStack(alignment: .bottom, spacing: 16) {
          VStack(alignment: .leading, spacing: 0) {
            HStack {
              SurfaceWordmark(title: snapshot.title, size: 15)
              SurfaceStatusDot(status: snapshot.status)
            }
            Spacer(minLength: 4)
            subtitle(palette)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          if snapshot.actions.isEmpty {
            // Nothing to measure or open yet, so the rings hold the space empty.
            SurfaceGauge(snapshot: snapshot)
              .frame(maxHeight: .infinity)
          } else {
            SurfaceActionRows(actions: snapshot.actions)
              .frame(maxWidth: 120)
          }
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func subtitle(_ palette: SurfacePalette) -> some View {
    Text(snapshot.subtitle)
      .font(SurfaceFont.onest(.medium, 15))
      .foregroundStyle(palette.text)
      .lineLimit(3)
      .minimumScaleFactor(0.8)
  }
}
