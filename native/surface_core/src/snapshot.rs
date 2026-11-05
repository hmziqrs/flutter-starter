//! The snapshot from `docs/native_surfaces.md`, and pure mapping into it.

use std::time::{SystemTime, UNIX_EPOCH};

use serde::Serialize;
use serde_json::Value;

pub const SCHEMA: u32 = 1;
const FALLBACK_TITLE: &str = "Starter";

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    Idle,
    Active,
    Warning,
    Failure,
}

#[derive(Debug, Serialize)]
pub struct Action {
    pub label: String,
    pub route: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotError {
    pub code: &'static str,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub http_status: Option<u16>,
}

/// Field order matches the documented snapshot. `value`, `valueLabel` and `progress`
/// serialize as null when missing. `error` is the one addition to the contract and is
/// only present on failure, so a success is exactly the documented shape.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Snapshot {
    pub schema: u32,
    pub title: String,
    pub subtitle: String,
    pub value: Option<String>,
    pub value_label: Option<String>,
    pub progress: Option<f64>,
    pub status: Status,
    pub updated_at: String,
    pub route: String,
    pub actions: Vec<Action>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<SnapshotError>,
}

impl Snapshot {
    pub fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| LAST_RESORT_JSON.to_owned())
    }
}

/// Returned when even building a snapshot failed. It has no timestamp because reading the
/// clock is one of the things that may have gone wrong.
pub const LAST_RESORT_JSON: &str = concat!(
    r#"{"schema":1,"title":"Starter","subtitle":"Could not refresh","value":null,"#,
    r#""valueLabel":null,"progress":null,"status":"failure","updatedAt":null,"route":"/","#,
    r#""actions":[],"error":{"code":"internal","message":"internal error in surface_core"}}"#,
);

/// `GET /v1/cache/welcome`, the signed-out source: `{ data: { message, progress? } }`.
pub fn from_welcome(body: &str, updated_at: String) -> Result<Snapshot, String> {
    let root: Value = serde_json::from_str(body).map_err(|e| format!("invalid JSON: {e}"))?;
    let data = root.get("data").ok_or("missing field: data")?;
    let message = data
        .get("message")
        .and_then(Value::as_str)
        .ok_or("missing field: data.message")?;
    let progress = data
        .get("progress")
        .and_then(Value::as_f64)
        .filter(|p| p.is_finite())
        .map(|p| p.clamp(0.0, 1.0));
    Ok(Snapshot {
        schema: SCHEMA,
        title: FALLBACK_TITLE.to_owned(),
        subtitle: message.to_owned(),
        value: progress.map(format_percent),
        value_label: progress.map(|_| "Complete".to_owned()),
        progress,
        status: if progress.is_some() {
            Status::Active
        } else {
            Status::Idle
        },
        updated_at,
        route: "/".to_owned(),
        actions: vec![Action {
            label: "Pricing".to_owned(),
            route: "/pricing".to_owned(),
        }],
        error: None,
    })
}

/// `GET /v1/profile`, the signed-in source: `{ displayName, username, email, bio }`.
/// The email is left out on purpose, because widgets show on the lock screen.
pub fn from_profile(body: &str, updated_at: String) -> Result<Snapshot, String> {
    let root: Value = serde_json::from_str(body).map_err(|e| format!("invalid JSON: {e}"))?;
    let display_name = root
        .get("displayName")
        .and_then(Value::as_str)
        .ok_or("missing field: displayName")?;
    let username = root
        .get("username")
        .and_then(Value::as_str)
        .ok_or("missing field: username")?;
    Ok(Snapshot {
        schema: SCHEMA,
        title: display_name.to_owned(),
        subtitle: format!("@{username}"),
        value: None,
        value_label: None,
        progress: None,
        status: Status::Idle,
        updated_at,
        route: "/".to_owned(),
        actions: vec![Action {
            label: "Profile".to_owned(),
            route: "/profile".to_owned(),
        }],
        error: None,
    })
}

/// A snapshot a widget can draw as is, with the reason in `error`.
pub fn failure(
    code: &'static str,
    message: String,
    http_status: Option<u16>,
    updated_at: String,
) -> Snapshot {
    let (status, subtitle) = match code {
        "unauthorized" => (Status::Warning, "Open the app to sign in"),
        _ => (Status::Failure, "Could not refresh"),
    };
    Snapshot {
        schema: SCHEMA,
        title: FALLBACK_TITLE.to_owned(),
        subtitle: subtitle.to_owned(),
        value: None,
        value_label: None,
        progress: None,
        status,
        updated_at,
        route: "/".to_owned(),
        actions: Vec::new(),
        error: Some(SnapshotError {
            code,
            message,
            http_status,
        }),
    }
}

/// `0.72` becomes `72%`. Clamps to 0..=1. Non-finite input has no meaningful value, so it
/// becomes `--`.
pub fn format_percent(progress: f64) -> String {
    if !progress.is_finite() {
        return "--".to_owned();
    }
    // Truncating cast is exact: the value is a rounded number in 0..=100.
    let percent = (progress.clamp(0.0, 1.0) * 100.0).round() as u32;
    format!("{percent}%")
}

/// The current time as `2026-11-05T01:00:00.000Z`, as the snapshot documents.
pub fn now_iso8601() -> String {
    let elapsed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    iso8601(elapsed.as_secs(), elapsed.subsec_millis())
}

/// Civil-from-days (Howard Hinnant's algorithm), to avoid a date crate for one format.
fn iso8601(unix_seconds: u64, millis: u32) -> String {
    let days = (unix_seconds / 86_400) as i64;
    let second_of_day = unix_seconds % 86_400;
    let z = days + 719_468;
    let era = z / 146_097;
    let day_of_era = z - era * 146_097;
    let year_of_era =
        (day_of_era - day_of_era / 1460 + day_of_era / 36_524 - day_of_era / 146_096) / 365;
    let day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let shifted_month = (5 * day_of_year + 2) / 153;
    let day = day_of_year - (153 * shifted_month + 2) / 5 + 1;
    let month = if shifted_month < 10 {
        shifted_month + 3
    } else {
        shifted_month - 9
    };
    let year = year_of_era + era * 400 + i64::from(month <= 2);
    format!(
        "{year:04}-{month:02}-{day:02}T{:02}:{:02}:{:02}.{millis:03}Z",
        second_of_day / 3600,
        second_of_day / 60 % 60,
        second_of_day % 60,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_percent() {
        for (input, expected) in [
            (0.72, "72%"),
            (0.0, "0%"),
            (1.0, "100%"),
            (0.005, "1%"),
            (0.29, "29%"),
            (0.57, "57%"),
            (-3.0, "0%"),
            (7.0, "100%"),
            (f64::NAN, "--"),
            (f64::INFINITY, "--"),
            (f64::NEG_INFINITY, "--"),
        ] {
            assert_eq!(format_percent(input), expected, "input {input}");
        }
    }

    #[test]
    fn formats_time_like_the_contract() {
        assert_eq!(iso8601(0, 0), "1970-01-01T00:00:00.000Z");
        assert_eq!(iso8601(951_782_400, 7), "2000-02-29T00:00:00.007Z");
        assert_eq!(iso8601(1_793_840_400, 0), "2026-11-05T01:00:00.000Z");
        assert_eq!(iso8601(4_107_542_399, 999), "2100-02-28T23:59:59.999Z");
    }

    #[test]
    fn success_is_exactly_the_documented_shape_and_order() {
        let body = r#"{"data":{"message":"Build running","progress":0.72}}"#;
        let json = from_welcome(body, "2026-11-05T01:00:00.000Z".to_owned())
            .unwrap()
            .to_json();
        assert_eq!(
            json,
            concat!(
                r#"{"schema":1,"title":"Starter","subtitle":"Build running","value":"72%","#,
                r#""valueLabel":"Complete","progress":0.72,"status":"active","#,
                r#""updatedAt":"2026-11-05T01:00:00.000Z","route":"/","#,
                r#""actions":[{"label":"Pricing","route":"/pricing"}]}"#,
            )
        );
    }

    #[test]
    fn missing_progress_serializes_as_null() {
        let json = from_welcome(r#"{"data":{"message":"Hi"}}"#, String::new())
            .unwrap()
            .to_json();
        assert!(json.contains(r#""value":null,"valueLabel":null,"progress":null"#));
        assert!(json.contains(r#""status":"idle""#));
    }

    #[test]
    fn out_of_range_progress_is_clamped() {
        let snapshot = from_welcome(r#"{"data":{"message":"x","progress":9}}"#, String::new());
        assert_eq!(snapshot.unwrap().progress, Some(1.0));
    }

    #[test]
    fn profile_leaves_the_email_out() {
        let body = r#"{"displayName":"Ada 🚀","username":"ada","email":"ada@x.test","bio":""}"#;
        let json = from_profile(body, String::new()).unwrap().to_json();
        assert!(json.contains(r#""title":"Ada 🚀""#));
        assert!(json.contains(r#""subtitle":"@ada""#));
        assert!(!json.contains("ada@x.test"));
    }

    #[test]
    fn bad_bodies_are_errors_not_panics() {
        for body in [
            "",
            "not json",
            "[]",
            "null",
            r#"{"data":1}"#,
            r#"{"data":{}}"#,
        ] {
            assert!(from_welcome(body, String::new()).is_err(), "body {body:?}");
            assert!(from_profile(body, String::new()).is_err(), "body {body:?}");
        }
        let deep = "[".repeat(100_000);
        assert!(from_welcome(&deep, String::new()).is_err());
    }

    #[test]
    fn failure_snapshot_is_drawable_and_carries_the_reason() {
        let parsed: Value = serde_json::from_str(
            &failure("timeout", "timed out".to_owned(), None, "t".to_owned()).to_json(),
        )
        .unwrap();
        assert_eq!(parsed["schema"], 1);
        assert_eq!(parsed["status"], "failure");
        assert_eq!(parsed["error"]["code"], "timeout");
        assert!(parsed["error"].get("httpStatus").is_none());
    }

    #[test]
    fn last_resort_json_is_valid() {
        let parsed: Value = serde_json::from_str(LAST_RESORT_JSON).unwrap();
        assert_eq!(parsed["error"]["code"], "internal");
    }
}
