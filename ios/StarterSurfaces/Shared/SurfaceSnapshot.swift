import Foundation

/// One tap target on a surface.
struct SurfaceAction: Codable, Hashable {
  let label: String
  let route: String
}

enum SurfaceStatus: String, Codable, Hashable {
  case idle
  case active
  case success
  case warning
  case failure

  /// A status this version does not know reads as `idle` instead of losing the whole snapshot.
  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = SurfaceStatus(rawValue: raw) ?? .idle
  }
}

/// What a surface draws, exactly as docs/native_surfaces.md defines it. Dart owns all of the text.
///
/// This is also the Live Activity's content state, which ActivityKit encodes and decodes on its
/// own. `updatedAt` stays the raw string so that round trip cannot change it.
struct SurfaceSnapshot: Codable, Hashable {
  static let schemaVersion = 1

  let schema: Int
  let title: String
  let subtitle: String
  let value: String?
  let valueLabel: String?
  let progress: Double?
  let status: SurfaceStatus
  let updatedAt: String?
  let route: String
  let actions: [SurfaceAction]

  /// Progress within 0...1, or nil when nothing is in progress.
  var clampedProgress: Double? { progress.map { min(max($0, 0), 1) } }

  var updatedDate: Date? { updatedAt.flatMap(SurfaceSnapshot.parseDate) }

  /// What surfaces show until the app publishes. The contract's only hardcoded text. The title is
  /// the extension's display name, so renaming the app renames it.
  static var fallback: SurfaceSnapshot {
    let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    return SurfaceSnapshot(
      schema: schemaVersion,
      title: name ?? "Starter",
      subtitle: "Open the app to get started",
      value: nil,
      valueLabel: nil,
      progress: nil,
      status: .idle,
      updatedAt: nil,
      route: "/",
      actions: []
    )
  }

  /// Decodes published JSON. Nil when it is unreadable or from a newer schema, which both mean
  /// the caller shows the fallback. The schema is read first, so a newer shape cannot misdecode.
  static func decode(json: String) -> SurfaceSnapshot? {
    guard let data = json.data(using: .utf8) else { return nil }
    let decoder = JSONDecoder()
    guard
      let probe = try? decoder.decode(SchemaProbe.self, from: data),
      probe.schema <= schemaVersion
    else { return nil }
    return try? decoder.decode(SurfaceSnapshot.self, from: data)
  }

  private struct SchemaProbe: Decodable {
    let schema: Int
  }

  /// Dart writes up to six fractional digits, which `ISO8601DateFormatter` does not reliably
  /// accept, and a surface only shows minutes. So the fraction is dropped before parsing.
  private static func parseDate(_ text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    guard let dot = text.firstIndex(of: ".") else { return formatter.date(from: text) }
    let fractionEnd = text[dot...].dropFirst().firstIndex { !$0.isNumber } ?? text.endIndex
    return formatter.date(from: String(text[..<dot] + text[fractionEnd...]))
  }
}

/// Where the app and its extension share the published snapshot. The group id comes from the
/// `SURFACE_APP_GROUP` build setting through each target's Info.plist.
enum SurfaceStore {
  static let key = "surface.snapshot"

  static var defaults: UserDefaults? {
    let group = Bundle.main.object(forInfoDictionaryKey: "SurfaceAppGroup") as? String
    return group.flatMap { UserDefaults(suiteName: $0) }
  }

  @discardableResult
  static func write(json: String) -> Bool {
    guard let defaults = defaults else { return false }
    defaults.set(json, forKey: key)
    return true
  }

  static func readJSON() -> String? { defaults?.string(forKey: key) }
}

/// `starter-surface://open?route=<percent-encoded route>`.
enum SurfaceLink {
  static let scheme = "starter-surface"
  private static let host = "open"
  private static let queryKey = "route"

  /// Everything except RFC 3986 unreserved characters is encoded, so `/`, `?` and `&` in a route
  /// cannot change the URL's shape.
  private static let unreserved = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

  static func url(route: String) -> URL? {
    guard let encoded = route.addingPercentEncoding(withAllowedCharacters: unreserved) else {
      return nil
    }
    return URL(string: "\(scheme)://\(host)?\(queryKey)=\(encoded)")
  }

  static func isSurfaceURL(_ url: URL) -> Bool { url.scheme?.lowercased() == scheme }

  /// The route in a surface URL. Dart checks it against the allowlist, so it is not validated here.
  static func route(from url: URL) -> String? {
    guard isSurfaceURL(url), url.host == host else { return nil }
    return URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first { $0.name == queryKey }?
      .value
  }
}
