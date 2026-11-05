import Foundation

/// What the app is doing. An unknown value reads as `idle`, so a newer app never breaks a
/// widget that is still running the older code.
enum SurfaceStatus: String {
  case idle, active, success, warning, failure
}

struct SurfaceAction: Equatable {
  let label: String
  let route: String
}

/// The JSON that Dart publishes. docs/native_surfaces.md is the contract.
struct SurfaceSnapshot: Equatable {
  static let schemaVersion = 1

  var title: String
  var subtitle: String
  var value: String?
  var valueLabel: String?
  var progress: Double?
  var status: SurfaceStatus = .idle
  var updatedAt: Date?
  var route: String = "/"
  var actions: [SurfaceAction] = []

  /// Shown when nothing has been published. The only text native code owns.
  static var fallback: SurfaceSnapshot {
    SurfaceSnapshot(title: appName, subtitle: "Open the app to get started")
  }

  /// The app's name from the running bundle's Info.plist, which `tool/rename_app.py` rewrites.
  static var appName: String {
    let info = Bundle.main.infoDictionary
    return info?["CFBundleDisplayName"] as? String ?? info?["CFBundleName"] as? String ?? "Starter"
  }

  /// Nil when the JSON is malformed, or written by a newer schema than this code knows.
  static func decode(json: String) -> SurfaceSnapshot? {
    guard
      let data = json.data(using: .utf8),
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let schema = root["schema"] as? Int, schema <= schemaVersion,
      let title = root["title"] as? String,
      let subtitle = root["subtitle"] as? String
    else { return nil }

    var snapshot = SurfaceSnapshot(title: title, subtitle: subtitle)
    snapshot.value = root["value"] as? String
    snapshot.valueLabel = root["valueLabel"] as? String
    snapshot.progress = (root["progress"] as? Double).map { min(max($0, 0), 1) }
    snapshot.status = (root["status"] as? String).flatMap(SurfaceStatus.init(rawValue:)) ?? .idle
    snapshot.updatedAt = (root["updatedAt"] as? String).flatMap(parseDate)
    snapshot.route = root["route"] as? String ?? "/"
    snapshot.actions = (root["actions"] as? [[String: Any]] ?? []).compactMap { action in
      guard let label = action["label"] as? String, let route = action["route"] as? String else {
        return nil
      }
      return SurfaceAction(label: label, route: route)
    }
    return snapshot
  }

  private static func parseDate(_ text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: text) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: text)
  }
}

/// Where the snapshot lives: the App Group's defaults, shared by the app and its widgets.
enum SurfaceStore {
  static let snapshotKey = "surface.snapshot"

  /// The App Group comes from the build settings through Info.plist, so `tool/rename_app.py` and
  /// the signing setup only have one place to change it (`AppInfo.xcconfig`).
  static var appGroup: String? {
    Bundle.main.object(forInfoDictionaryKey: "SurfaceAppGroup") as? String
  }

  static func defaults(suite: String? = appGroup) -> UserDefaults? {
    suite.flatMap(UserDefaults.init(suiteName:))
  }

  static func write(json: String, to defaults: UserDefaults? = defaults()) {
    defaults?.set(json, forKey: snapshotKey)
  }

  static func load(from defaults: UserDefaults? = defaults()) -> SurfaceSnapshot {
    defaults?.string(forKey: snapshotKey).flatMap(SurfaceSnapshot.decode(json:)) ?? .fallback
  }
}

/// `starter-surface://open?route=<percent-encoded route>`.
enum SurfaceLink {
  static let scheme = "starter-surface"
  private static let host = "open"
  private static let unreserved = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

  static func url(route: String) -> URL {
    let encoded = route.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
    return URL(string: "\(scheme)://\(host)?route=\(encoded)") ?? URL(fileURLWithPath: "/")
  }

  static func isSurfaceLink(_ url: URL) -> Bool {
    url.scheme?.lowercased() == scheme && url.host == host
  }

  /// The route is passed through unchecked. Dart checks each one against its allowlist.
  static func route(from url: URL) -> String? {
    guard isSurfaceLink(url) else { return nil }
    return URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first { $0.name == "route" }?.value
  }
}
