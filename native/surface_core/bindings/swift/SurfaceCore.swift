import SurfaceCoreFFI

/// Swift view of the C ABI. Copy the returned text and free the original in one place.
public enum SurfaceCore {
  public static var version: String {
    String(cString: surface_core_version())
  }

  /// Blocks for up to 5 seconds. Never call it on the main thread.
  public static func fetchSnapshot(baseURL: String, authToken: String?) -> String {
    take(surface_core_fetch_snapshot(baseURL, authToken))
  }

  /// Blocks for up to 5 seconds. Never call it on the main thread.
  public static func probe(url: String) -> String {
    take(surface_core_probe_url(url))
  }

  public static func formatPercent(_ progress: Double) -> String {
    take(surface_core_format_percent(progress))
  }

  private static func take(_ raw: UnsafeMutablePointer<CChar>?) -> String {
    guard let raw else { return "" }
    defer { surface_core_free(raw) }
    return String(cString: raw)
  }
}
