// surface_core: shared widget networking and data logic.
//
// All returned JSON is UTF-8. The functions never unwind into the caller and hold no state
// between calls. They read no files: the caller passes in the URL and token it has read from
// its own shared storage.

#ifndef SURFACE_CORE_H
#define SURFACE_CORE_H

#ifdef __cplusplus
extern "C" {
#endif

// The library version. Static storage: do NOT free it.
const char *surface_core_version(void);

// Fetches and returns snapshot JSON as documented in docs/native_surfaces.md.
//
// Signed in (non-empty token): GET {base_url}/v1/profile with a bearer token.
// Signed out (null or empty token): GET {base_url}/v1/cache/welcome.
//
// BLOCKS for up to 5 seconds. Never call it on the main thread. Thread-safe.
//
// On failure this still returns a snapshot a widget can draw, with status "failure" (or
// "warning" for a rejected token) and an extra field:
//   "error": { "code": "...", "message": "...", "httpStatus": 401 }
// code is one of: invalid_argument, timeout, network, tls, unauthorized, http_status,
// bad_response, internal. httpStatus is present only when a status caused the failure.
//
// Free the result with surface_core_free.
char *surface_core_fetch_snapshot(const char *base_url, const char *auth_token_or_null);

// Diagnostic GET of a full URL. BLOCKS like surface_core_fetch_snapshot. Returns:
//   { "ok": true, "httpStatus": 200, "bytes": 513, "elapsedMs": 120, "error": null }
// Free the result with surface_core_free.
char *surface_core_probe_url(const char *url);

// Formats 0.72 as "72%". Clamps to 0...1. NaN and infinity give "--". Does not block.
// Free the result with surface_core_free.
char *surface_core_format_percent(double progress);

// Frees a string returned by this library. Null is a no-op.
void surface_core_free(char *value);

#ifdef __cplusplus
}
#endif

#endif // SURFACE_CORE_H
