import SwiftUI
import WidgetKit

@main
struct SurfaceWidgetBundle: WidgetBundle {
  var body: some Widget {
    SurfaceWidget()
  }
}

struct SurfaceWidget: Widget {
  var body: some WidgetConfiguration {
    // The gallery's words are the app's own, read from what it last published.
    let snapshot = SurfaceStore.load()
    return StaticConfiguration(kind: "SurfaceWidget", provider: SurfaceTimelineProvider()) { entry in
      SurfaceWidgetEntryView(snapshot: entry.snapshot)
    }
    .configurationDisplayName(Text(verbatim: snapshot.title))
    .description(Text(verbatim: snapshot.subtitle))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .surfaceContentMarginsDisabled()
  }
}

struct SurfaceEntry: TimelineEntry {
  let date: Date
  let snapshot: SurfaceSnapshot
}

/// One entry and no schedule: `publish` reloads the timeline whenever there is something new.
struct SurfaceTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> SurfaceEntry {
    SurfaceEntry(date: Date(), snapshot: .fallback)
  }

  func getSnapshot(in context: Context, completion: @escaping (SurfaceEntry) -> Void) {
    completion(SurfaceEntry(date: Date(), snapshot: SurfaceStore.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SurfaceEntry>) -> Void) {
    let entry = SurfaceEntry(date: Date(), snapshot: SurfaceStore.load())
    completion(Timeline(entries: [entry], policy: .never))
  }
}

/// Reads what the system is doing with the widget, then hands plain values to the content view,
/// which stays free of system state so it can be rendered headlessly.
struct SurfaceWidgetEntryView: View {
  let snapshot: SurfaceSnapshot
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  init(snapshot: SurfaceSnapshot) {
    self.snapshot = snapshot
    SurfaceFont.registerBundled()
  }

  var body: some View {
    Group {
      if #available(macOS 13.0, *) {
        SurfaceWidgetModeReader(snapshot: snapshot, family: family, scheme: scheme)
      } else {
        SurfaceWidgetContent(
          snapshot: snapshot,
          family: family,
          palette: .forScheme(scheme)
        )
      }
    }
    .widgetURL(SurfaceLink.url(route: snapshot.route))
    .surfaceWidgetBackground(SurfacePalette.forScheme(scheme).page)
  }
}

@available(macOS 13.0, *)
private struct SurfaceWidgetModeReader: View {
  let snapshot: SurfaceSnapshot
  let family: WidgetFamily
  let scheme: ColorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  var body: some View {
    SurfaceWidgetContent(
      snapshot: snapshot,
      family: family,
      palette: renderingMode == .fullColor ? .forScheme(scheme) : .vibrant
    )
  }
}

extension View {
  @ViewBuilder
  fileprivate func surfaceWidgetBackground(_ color: Color) -> some View {
    if #available(macOS 14.0, *) {
      containerBackground(for: .widget) { color }
    } else {
      background(color)
    }
  }
}

extension WidgetConfiguration {
  /// The content lays out its own padding, the same on every macOS version.
  fileprivate func surfaceContentMarginsDisabled() -> some WidgetConfiguration {
    if #available(macOS 14.0, *) {
      return contentMarginsDisabled()
    } else {
      return self
    }
  }
}
