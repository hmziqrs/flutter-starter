import FlutterMacOS
import Foundation
import WidgetKit

/// The `starter/native_surfaces` channel (docs/native_surfaces.md).
final class NativeSurfaces {
  static let shared = NativeSurfaces()

  let routes = SurfaceRouteDesk()
  var snapshotDidChange: ((SurfaceSnapshot) -> Void)?
  private var channel: FlutterMethodChannel?

  private lazy var core = SurfaceChannelCore(routes: routes) { [weak self] json in
    SurfaceStore.write(json: json)
    WidgetCenter.shared.reloadAllTimelines()
    self?.snapshotDidChange?(SurfaceStore.load())
  }

  func attach(to messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "starter/native_surfaces", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return result(FlutterMethodNotImplemented) }
      switch self.core.handle(method: call.method, argument: call.arguments) {
      case .value(let value):
        result(value)
      case .notImplemented:
        result(FlutterMethodNotImplemented)
      case .badArgument(let message):
        result(FlutterError(code: "bad_argument", message: message, details: nil))
      }
    }
    routes.deliver = { [weak channel] route in
      channel?.invokeMethod("openRoute", arguments: route)
    }
    self.channel = channel
  }
}
