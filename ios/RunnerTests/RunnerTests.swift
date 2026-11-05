import XCTest

@testable import Runner

class SurfaceSnapshotTests: XCTestCase {
  private let contract = """
    {
      "schema": 1,
      "title": "Starter",
      "subtitle": "Build running",
      "value": "72%",
      "valueLabel": "Complete",
      "progress": 0.72,
      "status": "active",
      "updatedAt": "2026-11-05T01:00:00.000Z",
      "route": "/",
      "actions": [{ "label": "Pricing", "route": "/pricing" }]
    }
    """

  func testDecodesTheContractExample() throws {
    let snapshot = try XCTUnwrap(SurfaceSnapshot.decode(json: contract))
    XCTAssertEqual(snapshot.title, "Starter")
    XCTAssertEqual(snapshot.value, "72%")
    XCTAssertEqual(snapshot.clampedProgress, 0.72)
    XCTAssertEqual(snapshot.status, .active)
    XCTAssertEqual(snapshot.actions, [SurfaceAction(label: "Pricing", route: "/pricing")])
  }

  func testNullableFieldsMayBeNull() throws {
    let json = """
      {"schema":1,"title":"T","subtitle":"S","value":null,"valueLabel":null,"progress":null,
      "status":"idle","updatedAt":"2026-11-05T01:00:00.000Z","route":"/","actions":[]}
      """
    let snapshot = try XCTUnwrap(SurfaceSnapshot.decode(json: json))
    XCTAssertNil(snapshot.value)
    XCTAssertNil(snapshot.clampedProgress)
  }

  func testANewerSchemaIsIgnored() {
    let json = contract.replacingOccurrences(of: "\"schema\": 1", with: "\"schema\": 2")
    XCTAssertNil(SurfaceSnapshot.decode(json: json))
  }

  func testUnreadableJSONIsIgnored() {
    XCTAssertNil(SurfaceSnapshot.decode(json: "not json"))
    XCTAssertNil(SurfaceSnapshot.decode(json: "{\"schema\":1}"))
  }

  func testAnUnknownStatusReadsAsIdle() throws {
    let json = contract.replacingOccurrences(of: "\"active\"", with: "\"paused\"")
    XCTAssertEqual(try XCTUnwrap(SurfaceSnapshot.decode(json: json)).status, .idle)
  }

  func testProgressIsClamped() throws {
    let json = contract.replacingOccurrences(of: "0.72", with: "1.5")
    XCTAssertEqual(try XCTUnwrap(SurfaceSnapshot.decode(json: json)).clampedProgress, 1)
  }

  /// Dart's `toIso8601String` writes microseconds on native platforms.
  func testParsesDatesWithAnyFraction() throws {
    let expected = Date(timeIntervalSince1970: 1_793_840_400)
    for stamp in ["2026-11-05T01:00:00Z", "2026-11-05T01:00:00.000Z", "2026-11-05T01:00:00.123456Z"] {
      let json = contract.replacingOccurrences(of: "2026-11-05T01:00:00.000Z", with: stamp)
      XCTAssertEqual(try XCTUnwrap(SurfaceSnapshot.decode(json: json)).updatedDate, expected)
    }
  }

  func testSurvivesTheContentStateRoundTrip() throws {
    let snapshot = try XCTUnwrap(SurfaceSnapshot.decode(json: contract))
    let data = try JSONEncoder().encode(snapshot)
    XCTAssertEqual(try JSONDecoder().decode(SurfaceSnapshot.self, from: data), snapshot)
  }
}

class SurfaceLinkTests: XCTestCase {
  func testUsesTheContractShape() throws {
    let url = try XCTUnwrap(SurfaceLink.url(route: "/pricing"))
    XCTAssertEqual(url.absoluteString, "starter-surface://open?route=%2Fpricing")
  }

  func testRoundTripsRoutesWithReservedCharacters() throws {
    for route in ["/", "/pricing", "/a b", "/x?y=1&z=2", "/café"] {
      let url = try XCTUnwrap(SurfaceLink.url(route: route))
      XCTAssertEqual(SurfaceLink.route(from: url), route)
    }
  }

  func testIgnoresOtherURLs() throws {
    let other = try XCTUnwrap(URL(string: "https://example.com/open?route=%2Fpricing"))
    XCTAssertFalse(SurfaceLink.isSurfaceURL(other))
    XCTAssertNil(SurfaceLink.route(from: other))
    let noRoute = try XCTUnwrap(URL(string: "starter-surface://open"))
    XCTAssertTrue(SurfaceLink.isSurfaceURL(noRoute))
    XCTAssertNil(SurfaceLink.route(from: noRoute))
  }
}

class SurfaceStoreTests: XCTestCase {
  /// Proves the running app really has the App Group, not only that the file declares it.
  func testWritesToTheAppGroup() throws {
    let group = try XCTUnwrap(
      Bundle.main.object(forInfoDictionaryKey: "SurfaceAppGroup") as? String)
    XCTAssertTrue(group.hasPrefix("group."))
    let previous = SurfaceStore.readJSON()
    defer {
      if let previous = previous {
        SurfaceStore.write(json: previous)
      } else {
        UserDefaults(suiteName: group)?.removeObject(forKey: SurfaceStore.key)
      }
    }
    XCTAssertTrue(SurfaceStore.write(json: "{\"probe\":true}"))
    XCTAssertEqual(SurfaceStore.readJSON(), "{\"probe\":true}")
    XCTAssertEqual(UserDefaults(suiteName: group)?.string(forKey: "surface.snapshot"), "{\"probe\":true}")
  }
}
