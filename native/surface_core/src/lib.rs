//! Shared widget logic behind a small C ABI. See `include/surface_core.h` for the contract.
//!
//! Every export catches panics. A panic can only become a failure snapshot, never unwind into
//! Swift or Java. Allocation failure and stack overflow still abort, and no library can catch
//! those.

use std::ffi::{CStr, CString, c_char};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::ptr;

mod fetch;
mod snapshot;

#[cfg(target_os = "android")]
mod android;

pub(crate) use fetch::{Limits, fetch_snapshot, probe};
pub(crate) use snapshot::{LAST_RESORT_JSON, format_percent};

const VERSION: &CStr =
    match CStr::from_bytes_with_nul(concat!(env!("CARGO_PKG_VERSION"), "\0").as_bytes()) {
        Ok(version) => version,
        Err(_) => panic!("version has an interior NUL"),
    };

/// Runs `body`. A panic becomes `LAST_RESORT_JSON`.
pub(crate) fn guarded_json(body: impl FnOnce() -> String) -> String {
    catch_unwind(AssertUnwindSafe(body)).unwrap_or_else(|_| LAST_RESORT_JSON.to_owned())
}

fn into_c_string(text: String) -> *mut c_char {
    // Serde escapes NUL in JSON, and percent strings have none, so this cannot fail in
    // practice. Falling through to null keeps it safe if it ever did.
    CString::new(text).map_or(ptr::null_mut(), CString::into_raw)
}

/// Reads an optional C string. `Err` means the bytes are not UTF-8.
///
/// # Safety
/// `value` is null or points at a NUL-terminated string that stays valid during the call.
unsafe fn optional_str<'a>(value: *const c_char) -> Result<Option<&'a str>, ()> {
    if value.is_null() {
        return Ok(None);
    }
    // SAFETY: the caller guarantees a valid NUL-terminated string.
    unsafe { CStr::from_ptr(value) }
        .to_str()
        .map(Some)
        .map_err(|_| ())
}

fn invalid_argument(message: &str) -> String {
    snapshot::failure(
        "invalid_argument",
        message.to_owned(),
        None,
        snapshot::now_iso8601(),
    )
    .to_json()
}

/// The shared path behind the C and JNI exports. An empty token means signed out.
pub(crate) fn snapshot_json(base_url: Option<&str>, token: Option<&str>) -> String {
    let Some(base_url) = base_url else {
        return invalid_argument("base URL is required");
    };
    fetch_snapshot(base_url, token.filter(|t| !t.is_empty()), Limits::default())
}

/// The library version. Static storage: do not free it.
#[unsafe(no_mangle)]
pub extern "C" fn surface_core_version() -> *const c_char {
    VERSION.as_ptr()
}

/// Blocks until the fetch finishes or times out. Free the result with `surface_core_free`.
///
/// # Safety
/// `base_url` and `auth_token_or_null` are each null or a valid NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn surface_core_fetch_snapshot(
    base_url: *const c_char,
    auth_token_or_null: *const c_char,
) -> *mut c_char {
    into_c_string(guarded_json(|| {
        // SAFETY: forwarded from this function's own contract.
        let (base_url, token) =
            unsafe { (optional_str(base_url), optional_str(auth_token_or_null)) };
        match (base_url, token) {
            (Ok(base_url), Ok(token)) => snapshot_json(base_url, token),
            _ => invalid_argument("arguments must be UTF-8"),
        }
    }))
}

/// A diagnostic GET of `url`. Free the result with `surface_core_free`.
///
/// # Safety
/// `url` is null or a valid NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn surface_core_probe_url(url: *const c_char) -> *mut c_char {
    into_c_string(guarded_json(|| {
        // SAFETY: forwarded from this function's own contract.
        match unsafe { optional_str(url) } {
            Ok(Some(url)) => probe(url, Limits::default()),
            Ok(None) => probe("", Limits::default()),
            Err(()) => invalid_argument("arguments must be UTF-8"),
        }
    }))
}

/// `0.72` becomes `72%`. Free the result with `surface_core_free`.
#[unsafe(no_mangle)]
pub extern "C" fn surface_core_format_percent(progress: f64) -> *mut c_char {
    into_c_string(guarded_json(|| format_percent(progress)))
}

/// Frees a string this library returned. Null is a no-op.
///
/// # Safety
/// `value` is null, or came from this library and has not been freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn surface_core_free(value: *mut c_char) {
    if value.is_null() {
        return;
    }
    // Dropping a CString cannot panic, but the boundary rule is cheap to keep uniform.
    let _ = catch_unwind(AssertUnwindSafe(|| {
        // SAFETY: the caller guarantees this came from `CString::into_raw` here.
        drop(unsafe { CString::from_raw(value) });
    }));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_panic_becomes_a_failure_snapshot() {
        let json = guarded_json(|| panic!("forced"));
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["status"], "failure");
        assert_eq!(parsed["error"]["code"], "internal");
    }
}
