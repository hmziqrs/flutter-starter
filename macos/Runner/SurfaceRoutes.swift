import Foundation

/// Routes on their way into Dart. Before Dart has asked for the launch route, a route is held for
/// it, which covers a cold launch from a widget. After that, routes go straight to `openRoute`.
final class SurfaceRouteDesk {
  var deliver: ((String) -> Void)?
  private var heldRoute: String?
  private var dartIsListening = false

  func open(route: String) {
    if dartIsListening {
      deliver?(route)
    } else {
      heldRoute = route
    }
  }

  func takeLaunchRoute() -> String? {
    dartIsListening = true
    defer { heldRoute = nil }
    return heldRoute
  }
}

/// The channel's behavior, apart from Flutter so it can be tested without an engine.
final class SurfaceChannelCore {
  enum Reply {
    case value(Any?)
    case notImplemented
    case badArgument(String)
  }

  private let routes: SurfaceRouteDesk
  private let publish: (String) -> Void

  init(routes: SurfaceRouteDesk, publish: @escaping (String) -> Void) {
    self.routes = routes
    self.publish = publish
  }

  func handle(method: String, argument: Any?) -> Reply {
    switch method {
    case "publish":
      guard let json = argument as? String else {
        return .badArgument("publish takes the snapshot as one JSON string")
      }
      publish(json)
      return .value(nil)
    // macOS has no live surface. The menu bar item shows progress from `publish` instead.
    case "startLive":
      return .value(false)
    case "updateLive", "endLive":
      return .value(nil)
    case "takeLaunchRoute":
      return .value(routes.takeLaunchRoute())
    default:
      return .notImplemented
    }
  }
}
