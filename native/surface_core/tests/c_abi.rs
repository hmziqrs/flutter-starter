//! Calls the exported C functions the way Swift would, against the repo's real dummy backend.
//! Needs `bun` and `bun install --frozen-lockfile` in `tools/hono_server`.

use std::ffi::{CStr, CString, c_char};
use std::io::{BufRead, BufReader};
use std::net::TcpListener;
use std::path::Path;
use std::process::{Child, Command, Stdio};
use std::ptr;
use std::time::{Duration, Instant};

use serde_json::{Value, json};
use surface_core::{
    surface_core_fetch_snapshot, surface_core_format_percent, surface_core_free,
    surface_core_probe_url, surface_core_version,
};

struct Backend {
    child: Child,
    base_url: String,
}

impl Backend {
    fn start() -> Self {
        let free_port = TcpListener::bind("127.0.0.1:0").unwrap();
        let port = free_port.local_addr().unwrap().port();
        drop(free_port);
        let server = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../tools/hono_server");
        assert!(
            server.join("node_modules").exists(),
            "run `bun install --frozen-lockfile` in {}",
            server.display()
        );
        let mut child = Command::new("bun")
            .args(["run", "src/index.ts", "--port", &port.to_string()])
            .current_dir(&server)
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()
            .expect("bun must be on PATH to run the backend tests");
        let stdout = child.stdout.take().unwrap();
        let mut line = String::new();
        BufReader::new(stdout).read_line(&mut line).unwrap();
        assert!(line.contains("LISTENING"), "unexpected first line: {line}");
        Self {
            child,
            base_url: format!("http://127.0.0.1:{port}"),
        }
    }

    fn post(&self, path: &str, body: &Value) -> Value {
        let mut response = ureq::post(format!("{}{path}", self.base_url))
            .header("Content-Type", "application/json")
            .send(body.to_string())
            .unwrap();
        serde_json::from_str(&response.body_mut().read_to_string().unwrap()).unwrap()
    }

    /// Registers and verifies a real account, and returns its access token. `/v1/auth/issue`
    /// is not enough: its tokens map to no account, so `/v1/profile` answers 401.
    fn sign_in(&self) -> String {
        let registered = self.post(
            "/v1/auth/register",
            &json!({
                "email": "widget@example.test",
                "password": "dummy-backend-test-value",
                "displayName": "Widget 🚀 Tester",
            }),
        );
        let verified = self.post(
            "/v1/otp/verify",
            &json!({
                "attempt_token": registered["attempt_token"],
                "code": registered["dev_code"],
            }),
        );
        verified["access_token"].as_str().unwrap().to_owned()
    }
}

impl Drop for Backend {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
    }
}

/// Copies and frees a string returned by the library.
fn take(raw: *mut c_char) -> String {
    assert!(!raw.is_null());
    // SAFETY: the library returned it and it is freed exactly once, right here.
    unsafe {
        let text = CStr::from_ptr(raw).to_str().unwrap().to_owned();
        surface_core_free(raw);
        text
    }
}

fn fetch(base_url: &str, token: Option<&str>) -> Value {
    let base_url = CString::new(base_url).unwrap();
    let token = token.map(|t| CString::new(t).unwrap());
    let token_ptr = token.as_ref().map_or(ptr::null(), |t| t.as_ptr());
    // SAFETY: both pointers are valid for the call.
    let raw = unsafe { surface_core_fetch_snapshot(base_url.as_ptr(), token_ptr) };
    serde_json::from_str(&take(raw)).unwrap()
}

fn assert_documented_shape(snapshot: &Value) {
    let keys: Vec<&str> = snapshot
        .as_object()
        .unwrap()
        .keys()
        .map(String::as_str)
        .collect();
    let mut sorted_expected = [
        "schema",
        "title",
        "subtitle",
        "value",
        "valueLabel",
        "progress",
        "status",
        "updatedAt",
        "route",
        "actions",
    ];
    sorted_expected.sort_unstable();
    assert_eq!(keys, sorted_expected, "{snapshot}");
    assert_eq!(snapshot["schema"], 1);
    let updated_at = snapshot["updatedAt"].as_str().unwrap();
    assert_eq!(updated_at.len(), "2026-11-05T01:00:00.000Z".len());
    assert!(updated_at.ends_with('Z'));
}

#[test]
fn real_fetches_against_the_dummy_backend() {
    let backend = Backend::start();

    let signed_out = fetch(&backend.base_url, None);
    assert_documented_shape(&signed_out);
    assert_eq!(signed_out["title"], "Starter");
    assert_eq!(signed_out["subtitle"], "Welcome to the starter.");
    assert_eq!(signed_out["status"], "idle");
    assert_eq!(signed_out["actions"][0]["route"], "/pricing");

    assert_eq!(
        fetch(&backend.base_url, Some(""))["subtitle"],
        signed_out["subtitle"]
    );

    let token = backend.sign_in();
    let signed_in = fetch(&backend.base_url, Some(&token));
    assert_documented_shape(&signed_in);
    assert_eq!(signed_in["title"], "Widget 🚀 Tester");
    assert_eq!(signed_in["subtitle"], "@widget");
    assert_eq!(signed_in["actions"][0]["route"], "/profile");
    assert!(!signed_in.to_string().contains("widget@example.test"));

    let rejected = fetch(&backend.base_url, Some("not-a-real-token"));
    assert_eq!(rejected["status"], "warning");
    assert_eq!(rejected["error"]["code"], "unauthorized");
    assert_eq!(rejected["error"]["httpStatus"], 401);

    let url = CString::new(format!("{}/healthz", backend.base_url)).unwrap();
    // SAFETY: the pointer is valid for the call.
    let probe: Value =
        serde_json::from_str(&take(unsafe { surface_core_probe_url(url.as_ptr()) })).unwrap();
    assert_eq!(probe["ok"], true);
    assert_eq!(probe["httpStatus"], 200);
}

#[test]
fn the_real_five_second_timeout_holds_through_the_c_abi() {
    let silent = TcpListener::bind("127.0.0.1:0").unwrap();
    let base_url = format!("http://{}", silent.local_addr().unwrap());
    let started = Instant::now();
    let snapshot = fetch(&base_url, None);
    let elapsed = started.elapsed();
    assert_eq!(snapshot["error"]["code"], "timeout");
    assert!(
        (Duration::from_millis(4500)..Duration::from_millis(6000)).contains(&elapsed),
        "took {elapsed:?}"
    );
}

#[test]
fn null_and_invalid_arguments_do_not_crash() {
    // SAFETY: null is allowed by the contract.
    let snapshot = take(unsafe { surface_core_fetch_snapshot(ptr::null(), ptr::null()) });
    let snapshot: Value = serde_json::from_str(&snapshot).unwrap();
    assert_eq!(snapshot["error"]["code"], "invalid_argument");

    let bad_utf8 = [0xFF_u8, 0xFE, 0];
    // SAFETY: the buffer is NUL-terminated.
    let snapshot =
        take(unsafe { surface_core_fetch_snapshot(bad_utf8.as_ptr().cast(), ptr::null()) });
    let snapshot: Value = serde_json::from_str(&snapshot).unwrap();
    assert_eq!(snapshot["error"]["code"], "invalid_argument");

    // SAFETY: null is allowed by the contract.
    let probe = take(unsafe { surface_core_probe_url(ptr::null()) });
    assert!(probe.contains("invalid_argument"));

    // SAFETY: null is a documented no-op.
    unsafe { surface_core_free(ptr::null_mut()) };
}

#[test]
fn version_and_percent_cross_the_abi() {
    // SAFETY: the version pointer is static.
    let version = unsafe { CStr::from_ptr(surface_core_version()) };
    assert_eq!(version.to_str().unwrap(), env!("CARGO_PKG_VERSION"));
    assert_eq!(take(surface_core_format_percent(0.72)), "72%");
    assert_eq!(take(surface_core_format_percent(f64::NAN)), "--");
}
