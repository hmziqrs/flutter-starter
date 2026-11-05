import ActivityKit
import SwiftUI
import WidgetKit
import os

struct SurfaceEntry: TimelineEntry {
  let date: Date
  let snapshot: SurfaceSnapshot
}

/// One entry and no schedule: a surface changes only when the app publishes, which reloads it.
struct SurfaceTimelineProvider: TimelineProvider {
  private static let log = Logger(subsystem: "starter.native-surfaces", category: "timeline")

  func placeholder(in context: Context) -> SurfaceEntry {
    SurfaceEntry(date: Date(), snapshot: .fallback)
  }

  func getSnapshot(in context: Context, completion: @escaping (SurfaceEntry) -> Void) {
    completion(SurfaceEntry(date: Date(), snapshot: load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SurfaceEntry>) -> Void) {
    let entry = SurfaceEntry(date: Date(), snapshot: load())
    completion(Timeline(entries: [entry], policy: .never))
  }

  private func load() -> SurfaceSnapshot {
    guard let json = SurfaceStore.readJSON() else {
      Self.log.info("nothing published, using the fallback")
      return .fallback
    }
    guard let snapshot = SurfaceSnapshot.decode(json: json) else {
      Self.log.error("unreadable or newer snapshot, using the fallback")
      return .fallback
    }
    Self.log.info(
      "decoded schema \(snapshot.schema) status \(snapshot.status.rawValue, privacy: .public)")
    return snapshot
  }
}

/// Picks the view for the family, and supplies the background the OS expects.
struct SurfaceWidgetView: View {
  let snapshot: SurfaceSnapshot
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme
  @Environment(\.showsWidgetContainerBackground) private var showsBackground

  var body: some View {
    let page = isAccessory ? nil : SurfacePalette.of(scheme).page
    content
      // The container background alone comes out lighter than asked: on iOS 27 `#0A0A0A` measured
      // 24 to 39 on the home screen, which washes out the gauge's rings. So the page is painted
      // under the content as well, unless the system has removed the background, as on StandBy
      // and tinted home screens.
      .background(showsBackground ? page : nil)
      .widgetURL(SurfaceLink.url(route: snapshot.route))
      .surfaceBackground(page)
  }

  @ViewBuilder
  private var content: some View {
    switch family {
    case .systemMedium:
      HomeMediumView(snapshot: snapshot)
    case .systemSmall:
      HomeSmallView(snapshot: snapshot)
    default:
      if #available(iOS 16.0, *) {
        accessory
      } else {
        HomeSmallView(snapshot: snapshot)
      }
    }
  }

  @available(iOS 16.0, *)
  @ViewBuilder
  private var accessory: some View {
    switch family {
    case .accessoryCircular: LockCircularView(snapshot: snapshot)
    case .accessoryRectangular: LockRectangularView(snapshot: snapshot)
    case .accessoryInline: LockInlineView(snapshot: snapshot)
    default: HomeSmallView(snapshot: snapshot)
    }
  }

  private var isAccessory: Bool { family != .systemSmall && family != .systemMedium }
}

extension View {
  /// Since iOS 17 a widget without `containerBackground` shows an error in place of its content.
  @ViewBuilder
  fileprivate func surfaceBackground(_ color: Color?) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { color ?? Color.clear }
    } else if let color = color {
      background(color)
    } else {
      self
    }
  }
}

struct SurfaceWidget: Widget {
  private var families: [WidgetFamily] {
    var families: [WidgetFamily] = [.systemSmall, .systemMedium]
    if #available(iOS 16.0, *) {
      families += [.accessoryCircular, .accessoryRectangular, .accessoryInline]
    }
    return families
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "StarterSurface", provider: SurfaceTimelineProvider()) { entry in
      SurfaceWidgetView(snapshot: entry.snapshot)
    }
    .configurationDisplayName(SurfaceSnapshot.fallback.title)
    .description(SurfaceSnapshot.fallback.subtitle)
    .supportedFamilies(families)
    .contentMarginsDisabled()
  }
}

@available(iOS 16.2, *)
struct SurfaceLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: SurfaceActivityAttributes.self) { context in
      LiveBannerView(snapshot: context.state)
        .activityBackgroundTint(SurfacePalette.adaptivePage)
        .activitySystemActionForegroundColor(SurfacePalette.dark.muted)
        .widgetURL(SurfaceLink.url(route: context.state.route))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          LiveExpandedLeadingView(snapshot: context.state)
        }
        DynamicIslandExpandedRegion(.center) {
          LiveExpandedCenterView(snapshot: context.state)
        }
        // The figure and its caption must fit whole. The center text can truncate instead.
        DynamicIslandExpandedRegion(.trailing, priority: 1) {
          LiveExpandedTrailingView(snapshot: context.state)
        }
        DynamicIslandExpandedRegion(.bottom) {
          LiveExpandedBottomView(snapshot: context.state)
        }
      } compactLeading: {
        LiveCompactLeadingView(snapshot: context.state)
      } compactTrailing: {
        LiveCompactTrailingView(snapshot: context.state)
      } minimal: {
        LiveMinimalView(snapshot: context.state)
      }
      .widgetURL(SurfaceLink.url(route: context.state.route))
      .keylineTint(SurfacePalette.dark.accent)
    }
  }
}
