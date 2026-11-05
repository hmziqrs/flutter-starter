// Measures what the library adds to a linked binary. Build with no flag for the empty case,
// -D PURE for the pure functions only, and -D FULL for everything. Dead stripping decides how
// much of the archive each case keeps.
#if PURE || FULL
  import SurfaceCoreFFI
#endif

#if PURE
  let raw = surface_core_format_percent(0.5)
  print(String(cString: surface_core_version()), raw.map { String(cString: $0) } ?? "")
  surface_core_free(raw)
#elseif FULL
  let raw = surface_core_format_percent(0.5)
  let fetched = surface_core_fetch_snapshot("http://127.0.0.1:1", nil)
  let probed = surface_core_probe_url("http://127.0.0.1:1")
  print(String(cString: surface_core_version()), raw.map { String(cString: $0) } ?? "")
  print(fetched.map { String(cString: $0) } ?? "", probed.map { String(cString: $0) } ?? "")
  surface_core_free(raw)
  surface_core_free(fetched)
  surface_core_free(probed)
#else
  print("empty")
#endif
