import ActivityKit
import Foundation

/// The Live Activity's type. Compiled into the app, which starts it, and the extension, which
/// draws it. Everything it shows changes over time, so it all lives in the content state.
@available(iOS 16.2, *)
struct SurfaceActivityAttributes: ActivityAttributes {
  typealias ContentState = SurfaceSnapshot
}
