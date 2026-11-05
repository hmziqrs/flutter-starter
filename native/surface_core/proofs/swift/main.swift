// Throwaway proof, not app code. Modes:
//   baseline                 no library call, reports memory
//   fetch <base> [token]     one snapshot fetch, reports memory
//   https <url>              one TLS probe, reports memory
//   full <base> <token> <https-url> <bad-cert-url>
//                            every function, validated, with latency
//   soak <base> <count>      repeated fetches, reports memory drift
import Darwin
import Foundation
import SurfaceCoreFFI

struct Memory {
  let footprint: UInt64
  let footprintPeak: UInt64
  let resident: UInt64
  let residentPeak: UInt64

  static func now() -> Memory {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(
      MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
    let result = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
      }
    }
    precondition(result == KERN_SUCCESS, "task_info failed: \(result)")
    return Memory(
      footprint: info.phys_footprint,
      footprintPeak: UInt64(info.ledger_phys_footprint_peak),
      resident: info.resident_size,
      residentPeak: info.resident_size_peak)
  }

  func line(_ label: String) -> String {
    func mb(_ bytes: UInt64) -> String {
      String(format: "%.2f", Double(bytes) / 1_048_576)
    }
    return "MEM \(label) footprint_mb=\(mb(footprint)) footprint_peak_mb=\(mb(footprintPeak)) "
      + "rss_mb=\(mb(resident)) rss_peak_mb=\(mb(residentPeak))"
  }
}

func millis(_ body: () -> Void) -> Double {
  let start = DispatchTime.now().uptimeNanoseconds
  body()
  return Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
}

func stats(_ samples: [Double]) -> String {
  let sorted = samples.sorted()
  return String(
    format: "n=%d min=%.2f median=%.2f p95=%.2f max=%.2f ms", sorted.count, sorted[0],
    sorted[sorted.count / 2], sorted[min(sorted.count - 1, sorted.count * 95 / 100)],
    sorted[sorted.count - 1])
}

func json(_ text: String) -> [String: Any] {
  let parsed = try? JSONSerialization.jsonObject(with: Data(text.utf8))
  guard let object = parsed as? [String: Any] else {
    fatalError("not a JSON object: \(text)")
  }
  return object
}

func check(_ condition: Bool, _ label: String, _ detail: @autoclosure () -> String = "") {
  print("\(condition ? "PASS" : "FAIL") \(label) \(detail())")
  if !condition { exit(1) }
}

let args = CommandLine.arguments
let mode = args.count > 1 ? args[1] : "baseline"
print("PLATFORM \(platformName()) mode=\(mode)")

func platformName() -> String {
  #if targetEnvironment(simulator)
    return "ios-simulator"
  #elseif os(iOS)
    return "ios-device"
  #else
    return "macos"
  #endif
}

switch mode {
case "baseline":
  print(Memory.now().line("baseline"))

case "fetch":
  let before = Memory.now()
  let token = args.count > 3 ? args[3] : nil
  var output = ""
  let elapsed = millis { output = SurfaceCore.fetchSnapshot(baseURL: args[2], authToken: token) }
  let after = Memory.now()
  print(before.line("before"))
  print(after.line("after"))
  print(String(format: "LATENCY cold_fetch=%.2f ms", elapsed))
  print("OUTPUT \(output)")

case "https":
  let before = Memory.now()
  var output = ""
  let elapsed = millis { output = SurfaceCore.probe(url: args[2]) }
  let after = Memory.now()
  print(before.line("before"))
  print(after.line("after"))
  print(String(format: "LATENCY cold_https=%.2f ms", elapsed))
  print("OUTPUT \(output)")

case "full":
  let (base, token, httpsURL, badCertURL) = (args[2], args[3], args[4], args[5])

  check(!SurfaceCore.version.isEmpty, "version", SurfaceCore.version)
  check(SurfaceCore.formatPercent(0.72) == "72%", "format_percent", "0.72 -> 72%")
  check(SurfaceCore.formatPercent(.nan) == "--", "format_percent_nan")
  surface_core_free(nil)
  check(true, "free_null")

  let signedOutText = SurfaceCore.fetchSnapshot(baseURL: base, authToken: nil)
  print("OUTPUT signed_out \(signedOutText)")
  let signedOut = json(signedOutText)
  check(signedOut["schema"] as? Int == 1, "signed_out_schema")
  check(signedOut["error"] == nil, "signed_out_no_error")
  check(signedOut["subtitle"] as? String == "Welcome to the starter.", "signed_out_mapped")

  let signedInText = SurfaceCore.fetchSnapshot(baseURL: base, authToken: token)
  print("OUTPUT signed_in \(signedInText)")
  let signedIn = json(signedInText)
  check(signedIn["error"] == nil, "signed_in_no_error")
  check(signedIn["title"] as? String == "Proof \u{1F680}", "signed_in_utf8_round_trip")

  let rejected = json(SurfaceCore.fetchSnapshot(baseURL: base, authToken: "not-a-real-token"))
  check(rejected["status"] as? String == "warning", "rejected_token_warning")

  let refused = json(SurfaceCore.fetchSnapshot(baseURL: "http://127.0.0.1:1", authToken: nil))
  let refusedError = refused["error"] as? [String: Any]
  check(refusedError?["code"] as? String == "network", "refused_is_network_error")

  surface_core_fetch_snapshot(nil, nil).map { raw in
    let output = String(cString: raw)
    surface_core_free(raw)
    check(output.contains("invalid_argument"), "null_base_url_no_crash")
  }

  let httpsText = SurfaceCore.probe(url: httpsURL)
  print("OUTPUT https \(httpsText)")
  check(json(httpsText)["ok"] as? Bool == true, "https_public_host_ok")

  let snapshotOverTLS = SurfaceCore.fetchSnapshot(baseURL: httpsURL, authToken: nil)
  print("OUTPUT snapshot_over_tls \(snapshotOverTLS)")
  let tlsError = json(snapshotOverTLS)["error"] as? [String: Any]
  check(tlsError?["httpStatus"] != nil, "snapshot_path_completes_tls", "status came over TLS")

  var badCert = json(SurfaceCore.probe(url: badCertURL))
  for _ in 0..<5 where (badCert["error"] as? [String: Any])?["code"] as? String == "timeout" {
    badCert = json(SurfaceCore.probe(url: badCertURL))
  }
  let badCertError = badCert["error"] as? [String: Any]
  print("OUTPUT bad_cert \(badCert)")
  check(badCertError?["code"] as? String == "tls", "bad_certificate_rejected")

  var percentSamples: [Double] = []
  for _ in 0..<1000 { percentSamples.append(millis { _ = SurfaceCore.formatPercent(0.5) }) }
  print("LATENCY format_percent \(stats(percentSamples))")

  var fetchSamples: [Double] = []
  for _ in 0..<30 {
    fetchSamples.append(millis { _ = SurfaceCore.fetchSnapshot(baseURL: base, authToken: nil) })
  }
  print("LATENCY local_fetch \(stats(fetchSamples))")

  var httpsSamples: [Double] = []
  for _ in 0..<5 { httpsSamples.append(millis { _ = SurfaceCore.probe(url: httpsURL) }) }
  print("LATENCY https_probe \(stats(httpsSamples))")

  print(Memory.now().line("end_of_full"))
  print("RESULT ok")

case "soak":
  let (base, count) = (args[2], Int(args[3]) ?? 200)
  print(Memory.now().line("start"))
  for index in 1...count {
    _ = SurfaceCore.fetchSnapshot(baseURL: base, authToken: nil)
    if index % (count / 4) == 0 { print(Memory.now().line("after_\(index)")) }
  }

default:
  fatalError("unknown mode \(mode)")
}
