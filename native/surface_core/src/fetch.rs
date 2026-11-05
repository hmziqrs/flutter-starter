//! Blocking HTTP. A fresh agent per call: widgets fetch once and exit, and holding no global
//! state means nothing stays resident between calls.

use std::time::{Duration, Instant};

use serde::Serialize;
use ureq::config::RedirectAuthHeaders;

use crate::snapshot::{self, Snapshot};

/// Whole-call budget. Android's broadcast window is about 10 seconds and WidgetKit gives no
/// firm figure, so this stays well inside both.
const GLOBAL_TIMEOUT: Duration = Duration::from_secs(5);
const STAGE_TIMEOUT: Duration = Duration::from_secs(3);
/// A snapshot source is small. The limit keeps a bad response from costing widget memory.
const BODY_LIMIT: u64 = 256 * 1024;
const MAX_REDIRECTS: u32 = 2;
const USER_AGENT: &str = concat!("surface_core/", env!("CARGO_PKG_VERSION"));

#[derive(Debug, Clone, Copy)]
pub struct Limits {
    pub global: Duration,
    pub stage: Duration,
    pub body: u64,
}

impl Default for Limits {
    fn default() -> Self {
        Self {
            global: GLOBAL_TIMEOUT,
            stage: STAGE_TIMEOUT,
            body: BODY_LIMIT,
        }
    }
}

#[derive(Debug)]
pub struct Failure {
    pub code: &'static str,
    pub message: String,
    pub http_status: Option<u16>,
}

impl Failure {
    fn new(code: &'static str, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
            http_status: None,
        }
    }

    fn status(code: &'static str, message: impl Into<String>, status: u16) -> Self {
        Self {
            http_status: Some(status),
            ..Self::new(code, message)
        }
    }
}

/// Maps ureq errors to stable codes. Messages come from ureq and rustls, which never echo
/// request headers, so the token cannot reach the output this way.
fn classify(error: &ureq::Error) -> Failure {
    use std::io::ErrorKind;
    match error {
        ureq::Error::Timeout(_) => Failure::new("timeout", error.to_string()),
        ureq::Error::Io(io) if io.kind() == ErrorKind::TimedOut => {
            Failure::new("timeout", error.to_string())
        }
        ureq::Error::Rustls(_) | ureq::Error::Tls(_) | ureq::Error::Pem(_) => {
            Failure::new("tls", error.to_string())
        }
        // rustls reports a failed handshake through the socket's io::Error.
        ureq::Error::Io(io) if io.get_ref().is_some_and(|inner| is_tls_error(inner)) => {
            Failure::new("tls", error.to_string())
        }
        ureq::Error::HostNotFound | ureq::Error::ConnectionFailed | ureq::Error::Io(_) => {
            Failure::new("network", error.to_string())
        }
        ureq::Error::BodyExceedsLimit(_) => Failure::new("bad_response", error.to_string()),
        ureq::Error::BadUri(_) => Failure::new("invalid_argument", "base URL is not a valid URL"),
        _ => Failure::new("bad_response", error.to_string()),
    }
}

fn is_tls_error(inner: &(dyn std::error::Error + Send + Sync + 'static)) -> bool {
    let text = inner.to_string();
    text.contains("certificate")
        || text.contains("handshake")
        || text.contains("TLS")
        || text.contains("tls")
        || text.contains("received fatal alert")
}

fn agent(limits: Limits) -> ureq::Agent {
    ureq::Agent::config_builder()
        .http_status_as_error(false)
        .timeout_global(Some(limits.global))
        .timeout_resolve(Some(limits.stage))
        .timeout_connect(Some(limits.stage))
        .max_redirects(MAX_REDIRECTS)
        .redirect_auth_headers(RedirectAuthHeaders::Never)
        .max_idle_connections(0)
        .max_idle_connections_per_host(0)
        .proxy(None)
        .user_agent(USER_AGENT)
        .build()
        .new_agent()
}

fn check_base_url(base_url: &str) -> Result<(), Failure> {
    let rest = base_url
        .strip_prefix("https://")
        .or_else(|| base_url.strip_prefix("http://"))
        .ok_or_else(|| Failure::new("invalid_argument", "base URL must start with http(s)://"))?;
    let authority = rest.split(['/', '?', '#']).next().unwrap_or_default();
    if authority.is_empty() {
        return Err(Failure::new("invalid_argument", "base URL has no host"));
    }
    if authority.contains('@') {
        return Err(Failure::new(
            "invalid_argument",
            "base URL must not carry credentials",
        ));
    }
    Ok(())
}

/// Bearer tokens are `token68`. Checked here so a bad one is rejected with a message that
/// cannot quote it.
fn check_token(token: &str) -> Result<(), Failure> {
    if token.bytes().all(|b| b.is_ascii_graphic()) {
        Ok(())
    } else {
        Err(Failure::new(
            "invalid_argument",
            "auth token has characters that are not allowed in a header",
        ))
    }
}

fn get_source(base_url: &str, token: Option<&str>, limits: Limits) -> Result<Snapshot, Failure> {
    check_base_url(base_url)?;
    let base = base_url.trim_end_matches('/');
    let path = if token.is_some() {
        "/v1/profile"
    } else {
        "/v1/cache/welcome"
    };
    let mut request = agent(limits)
        .get(format!("{base}{path}"))
        .header("Accept", "application/json");
    if let Some(token) = token {
        check_token(token)?;
        request = request.header("Authorization", format!("Bearer {token}"));
    }
    let mut response = request.call().map_err(|e| classify(&e))?;
    let status = response.status().as_u16();
    match status {
        200 => {}
        401 | 403 => {
            return Err(Failure::status(
                "unauthorized",
                "the server rejected the auth token",
                status,
            ));
        }
        _ => {
            return Err(Failure::status(
                "http_status",
                format!("{path} returned HTTP {status}"),
                status,
            ));
        }
    }
    let body = response
        .body_mut()
        .with_config()
        .limit(limits.body)
        .read_to_string()
        .map_err(|e| classify(&e))?;
    let mapped = if token.is_some() {
        snapshot::from_profile(&body, snapshot::now_iso8601())
    } else {
        snapshot::from_welcome(&body, snapshot::now_iso8601())
    };
    mapped.map_err(|message| Failure::new("bad_response", format!("{path}: {message}")))
}

/// Always returns snapshot JSON. Failures are in its `error` field.
pub fn fetch_snapshot(base_url: &str, token: Option<&str>, limits: Limits) -> String {
    match get_source(base_url, token, limits) {
        Ok(snapshot) => snapshot.to_json(),
        Err(f) => {
            snapshot::failure(f.code, f.message, f.http_status, snapshot::now_iso8601()).to_json()
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ProbeReport {
    ok: bool,
    http_status: Option<u16>,
    bytes: Option<usize>,
    elapsed_ms: u64,
    error: Option<snapshot::SnapshotError>,
}

/// A plain GET that reports what happened. It is how TLS is proven against a public host
/// that has no snapshot routes.
pub fn probe(url: &str, limits: Limits) -> String {
    let started = Instant::now();
    let outcome = check_base_url(url).and_then(|()| {
        let mut response = agent(limits).get(url).call().map_err(|e| classify(&e))?;
        let status = response.status().as_u16();
        let bytes = response
            .body_mut()
            .with_config()
            .limit(limits.body)
            .read_to_vec()
            .map_err(|e| classify(&e))?;
        Ok((status, bytes.len()))
    });
    let elapsed_ms = u64::try_from(started.elapsed().as_millis()).unwrap_or(u64::MAX);
    let report = match outcome {
        Ok((status, bytes)) => ProbeReport {
            ok: (200..300).contains(&status),
            http_status: Some(status),
            bytes: Some(bytes),
            elapsed_ms,
            error: None,
        },
        Err(f) => ProbeReport {
            ok: false,
            http_status: f.http_status,
            bytes: None,
            elapsed_ms,
            error: Some(snapshot::SnapshotError {
                code: f.code,
                message: f.message,
                http_status: f.http_status,
            }),
        },
    };
    serde_json::to_string(&report).unwrap_or_else(|_| snapshot::LAST_RESORT_JSON.to_owned())
}

#[cfg(test)]
mod tests {
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::mpsc;
    use std::thread;

    use serde_json::Value;

    use super::*;

    const FAST: Limits = Limits {
        global: Duration::from_millis(400),
        stage: Duration::from_millis(400),
        body: 1024,
    };

    /// Answers one connection with `response`, and sends back the request it received.
    fn serve_once(response: Vec<u8>) -> (String, mpsc::Receiver<String>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let base = format!("http://{}", listener.local_addr().unwrap());
        let (sender, receiver) = mpsc::channel();
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            let mut request = Vec::new();
            let mut chunk = [0_u8; 1024];
            while !request.windows(4).any(|w| w == b"\r\n\r\n") {
                let read = stream.read(&mut chunk).unwrap();
                if read == 0 {
                    break;
                }
                request.extend_from_slice(&chunk[..read]);
            }
            let _ = sender.send(String::from_utf8_lossy(&request).into_owned());
            let _ = stream.write_all(&response);
        });
        (base, receiver)
    }

    fn http(status_line: &str, body: &str) -> Vec<u8> {
        format!(
            "HTTP/1.1 {status_line}\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\
             Connection: close\r\n\r\n{body}",
            body.len()
        )
        .into_bytes()
    }

    fn parse(json: &str) -> Value {
        serde_json::from_str(json).unwrap()
    }

    #[test]
    fn signed_out_requests_the_welcome_source_without_auth() {
        let (base, request) = serve_once(http("200 OK", r#"{"data":{"message":"Hello"}}"#));
        let out = parse(&fetch_snapshot(&format!("{base}/"), None, FAST));
        assert_eq!(out["subtitle"], "Hello");
        assert!(out.get("error").is_none());
        let request = request.recv().unwrap();
        assert!(request.starts_with("GET /v1/cache/welcome "), "{request}");
        assert!(!request.to_lowercase().contains("authorization"));
    }

    #[test]
    fn signed_in_sends_the_bearer_token_to_the_profile_source() {
        let body = r#"{"displayName":"Ada","username":"ada"}"#;
        let (base, request) = serve_once(http("200 OK", body));
        let out = parse(&fetch_snapshot(&base, Some("tok123"), FAST));
        assert_eq!(out["title"], "Ada");
        let request = request.recv().unwrap();
        assert!(request.starts_with("GET /v1/profile "), "{request}");
        assert!(request.contains("Bearer tok123"), "{request}");
    }

    #[test]
    fn rejected_token_is_a_warning_and_is_not_echoed() {
        let (base, _request) = serve_once(http("401 Unauthorized", r#"{"error":"unauthorized"}"#));
        let json = fetch_snapshot(&base, Some("secret-token"), FAST);
        let out = parse(&json);
        assert_eq!(out["status"], "warning");
        assert_eq!(out["error"]["code"], "unauthorized");
        assert_eq!(out["error"]["httpStatus"], 401);
        assert!(!json.contains("secret-token"));
    }

    #[test]
    fn server_error_carries_the_status() {
        let (base, _request) = serve_once(http("503 Service Unavailable", "busy"));
        let out = parse(&fetch_snapshot(&base, None, FAST));
        assert_eq!(out["status"], "failure");
        assert_eq!(out["error"]["code"], "http_status");
        assert_eq!(out["error"]["httpStatus"], 503);
    }

    #[test]
    fn malformed_body_is_a_bad_response() {
        let (base, _request) = serve_once(http("200 OK", "<html>nope</html>"));
        let out = parse(&fetch_snapshot(&base, None, FAST));
        assert_eq!(out["error"]["code"], "bad_response");
    }

    #[test]
    fn oversized_body_is_refused() {
        let body = format!(r#"{{"data":{{"message":"{}"}}}}"#, "x".repeat(4096));
        let (base, _request) = serve_once(http("200 OK", &body));
        let out = parse(&fetch_snapshot(&base, None, FAST));
        assert_eq!(out["error"]["code"], "bad_response");
    }

    #[test]
    fn silent_server_hits_the_timeout() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let base = format!("http://{}", listener.local_addr().unwrap());
        let started = Instant::now();
        let out = parse(&fetch_snapshot(&base, None, FAST));
        assert_eq!(out["error"]["code"], "timeout");
        assert!(started.elapsed() < Duration::from_secs(2));
        drop(listener);
    }

    #[test]
    fn refused_connection_is_a_network_error() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let base = format!("http://{}", listener.local_addr().unwrap());
        drop(listener);
        let out = parse(&fetch_snapshot(&base, None, FAST));
        assert_eq!(out["error"]["code"], "network");
    }

    #[test]
    fn redirect_does_not_forward_the_token() {
        let target_body = r#"{"displayName":"Ada","username":"ada"}"#;
        let (target, target_request) = serve_once(http("200 OK", target_body));
        let redirect = format!(
            "HTTP/1.1 302 Found\r\nLocation: {target}/v1/profile\r\nContent-Length: 0\r\n\
             Connection: close\r\n\r\n"
        );
        let (base, first_request) = serve_once(redirect.into_bytes());
        fetch_snapshot(&base, Some("secret-token"), FAST);
        assert!(first_request.recv().unwrap().contains("secret-token"));
        assert!(!target_request.recv().unwrap().contains("secret-token"));
    }

    #[test]
    fn bad_arguments_are_rejected_before_any_network() {
        for url in ["", "ftp://x", "example.com", "https://", "http://u:p@host/"] {
            let out = parse(&fetch_snapshot(url, None, FAST));
            assert_eq!(out["error"]["code"], "invalid_argument", "url {url:?}");
        }
        let json = fetch_snapshot("http://127.0.0.1:1", Some("bad\r\nX-Injected: 1"), FAST);
        assert_eq!(parse(&json)["error"]["code"], "invalid_argument");
        assert!(!json.contains("X-Injected"));
    }

    #[test]
    fn probe_reports_status_and_bytes() {
        let (base, _request) = serve_once(http("200 OK", "hello"));
        let out = parse(&probe(&base, FAST));
        assert_eq!(out["ok"], true);
        assert_eq!(out["httpStatus"], 200);
        assert_eq!(out["bytes"], 5);
    }

    /// Needs the internet: `cargo test -- --ignored`.
    #[test]
    #[ignore = "needs the public internet"]
    fn https_reaches_a_public_host() {
        let out = parse(&probe("https://example.com/", Limits::default()));
        assert_eq!(out["ok"], true, "{out}");
    }

    /// Without this, a verifier that accepted everything would pass the test above.
    ///
    /// The path to badssl.com drops SYNs (curl times out about 1 in 10 at the same limit). A
    /// connect timeout says nothing about certificates, so it is retried, never accepted.
    #[test]
    #[ignore = "needs the public internet"]
    fn https_rejects_bad_certificates() {
        for url in [
            "https://expired.badssl.com/",
            "https://wrong.host.badssl.com/",
            "https://self-signed.badssl.com/",
            "https://untrusted-root.badssl.com/",
        ] {
            let mut out = parse(&probe(url, Limits::default()));
            for _ in 0..5 {
                if out["error"]["code"] != "timeout" {
                    break;
                }
                out = parse(&probe(url, Limits::default()));
            }
            assert_eq!(out["ok"], false, "{url}: {out}");
            assert_eq!(out["error"]["code"], "tls", "{url}: {out}");
        }
    }
}
