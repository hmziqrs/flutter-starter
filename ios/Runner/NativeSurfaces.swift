import ActivityKit
import Flutter
import Foundation
import WidgetKit
import os

/// The native end of the `starter/native_surfaces` channel. See docs/native_surfaces.md.
final class NativeSurfaces {
  static let shared = NativeSurfaces()

  private static let channelName = "starter/native_surfaces"
  private static let log = Logger(subsystem: "starter.native-surfaces", category: "channel")

  private var channel: FlutterMethodChannel?
  private var pendingRoute: String?
  /// Set by the first `takeLaunchRoute`. Before that, Dart may not be listening yet, so a tapped
  /// route waits for that call. After it, routes go straight to `openRoute`.
  private var dartIsListening = false

  private init() {}

  func attach(to messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
  }

  /// Takes a surface URL from a tap. Returns false for any other URL, which the caller passes on
  /// to Flutter and its plugins.
  @discardableResult
  func open(_ url: URL) -> Bool {
    guard SurfaceLink.isSurfaceURL(url) else { return false }
    guard let route = SurfaceLink.route(from: url) else { return true }
    if dartIsListening {
      channel?.invokeMethod("openRoute", arguments: route)
    } else {
      pendingRoute = route
    }
    return true
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "publish":
      guard let json = snapshotJSON(call, result) else { return }
      guard SurfaceStore.write(json: json) else {
        result(FlutterError(code: "no_app_group", message: "App Group unavailable", details: nil))
        return
      }
      WidgetCenter.shared.reloadAllTimelines()
      result(nil)
    case "startLive":
      guard let json = snapshotJSON(call, result) else { return }
      startLive(json: json, result: result)
    case "updateLive":
      guard let json = snapshotJSON(call, result) else { return }
      updateLive(json: json, result: result)
    case "endLive":
      endLive(result: result)
    case "takeLaunchRoute":
      dartIsListening = true
      result(pendingRoute)
      pendingRoute = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func snapshotJSON(_ call: FlutterMethodCall, _ result: FlutterResult) -> String? {
    guard let json = call.arguments as? String else {
      result(FlutterError(code: "bad_argument", message: "Expected snapshot JSON", details: nil))
      return nil
    }
    return json
  }

  // MARK: Live Activity

  private func startLive(json: String, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *), let snapshot = SurfaceSnapshot.decode(json: json) else {
      result(false)
      return
    }
    Task { @MainActor in result(await LiveSession.start(snapshot)) }
  }

  private func updateLive(json: String, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *), let snapshot = SurfaceSnapshot.decode(json: json) else {
      result(nil)
      return
    }
    Task { @MainActor in
      await LiveSession.update(snapshot)
      result(nil)
    }
  }

  private func endLive(result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(nil)
      return
    }
    Task { @MainActor in
      await LiveSession.end()
      result(nil)
    }
  }

  @available(iOS 16.2, *)
  private enum LiveSession {
    private static var running: [Activity<SurfaceActivityAttributes>] {
      Activity<SurfaceActivityAttributes>.activities.filter {
        $0.activityState == .active || $0.activityState == .stale
      }
    }

    static func start(_ snapshot: SurfaceSnapshot) async -> Bool {
      guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
      let content = ActivityContent(state: snapshot, staleDate: nil)
      // A session can outlive the process that started it, so one that is still up continues.
      if let current = running.first {
        await current.update(content)
        return true
      }
      do {
        _ = try Activity.request(attributes: SurfaceActivityAttributes(), content: content)
        return true
      } catch {
        NativeSurfaces.log.error("startLive failed: \(error.localizedDescription, privacy: .public)")
        return false
      }
    }

    static func update(_ snapshot: SurfaceSnapshot) async {
      let content = ActivityContent(state: snapshot, staleDate: nil)
      for activity in running {
        await activity.update(content)
      }
    }

    static func end() async {
      for activity in running {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  }
}
