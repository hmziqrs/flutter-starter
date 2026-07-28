# Test server

A standalone [shelf](https://pub.dev/packages/shelf) server that implements the
backend contracts the starter's optional "real impl" adapters talk to, for
**development runs** and **integration tests**. It satisfies contracts C3 and C9
in [`plans/feature_roadmap/contracts.md`](../../plans/feature_roadmap/contracts.md).

> **Never compiled into the app.** This package has no path into `lib/`, is not a
> Flutter dependency, and is excluded from every release target. It exists only to
> give the optional real adapters a live local endpoint to hit — the app ships
> zero-backend by default (C2).

## Run

```
dart run tools/test_server/bin/server.dart --port 8080
# or, via env var
PORT=8081 dart run tools/test_server/bin/server.dart
```

The server binds to loopback (`127.0.0.1`), defaults to port `8080`, and prints
`LISTENING <port>` once bound. iOS Simulator, macOS, and the Android emulator
(the emulator reaches the host loopback via `10.0.2.2`) can all reach it.

> The justfile exposes this as `just test-server` (see the root `justfile`).

## Route table

| Method | Path                                  | Contract (C9)        | Notes |
| ------ | ------------------------------------- | -------------------- | ----- |
| GET    | `/healthz`                            | —                    | Liveness probe. `200 ok`. |
| POST   | `/v1/crashes`                         | crash-reporting      | Body `{message, stack?, context, platform, appVersion}` -> `204`. In-memory ring of the last 50 (not exposed over HTTP). |
| GET    | `/v1/remote-config`                   | remote-config family | `?deviceId=&platform=&version=` -> `{flags, versionPolicy, experiments, revision}`. `If-None-Match` / `?rev=` -> `304`. |
| POST   | `/v1/auth/{issue,refresh,logout}`     | session              | Issue/refresh/logout a session. In-memory token table; the optional real adapter points here. |
| POST   | `/v1/events`                          | analytics            | Batched analytics events -> `204`. |
| POST   | `/v1/feedback`                        | feedback             | `{message, email?, screenshotMime?, screenshotBase64?, appMetadata?}` -> `201 {id}`; `422` invalid; `413` screenshot too large. |
| GET    | `/v1/feedback/{id}/status`            | feedback             | `200 {state}` for a known id; `404` unknown. |
| POST   | `/v1/notifications/register-token`    | push-notifications   | Token registration only (FCM/APNs delivery is not mocked by a plain HTTP server). |
| DELETE | `/v1/notifications/register-token/{token}` | push-notifications | Unregister a token. |
| POST   | `/v1/notifications/permission-revoked`| push-notifications   | Signal the user revoked notification permission. |
| POST   | `/v1/otp/{issue,verify,resend}`       | mfa-otp              | Issue/verify/resend a one-time code. `429 locked` agrees with the client cooldown. |
| GET    | `/v1/cache/{key}`                     | offline-cache        | `200 {data, etag, ttlSeconds, epoch}` for a known key; `304` on matching `If-None-Match` (or `*`) and when `?minEpoch=` is not strictly older; `404` unknown. Prime via `routes.cache.primeCacheEntry`. |

`/v1/` is the uniform versioning prefix for every app-facing route (C9).

### Remote-config payload

`GET /v1/remote-config` returns a single cacheable response. The three
remote-config readers — `FeatureFlagsSource`, `VersionGateStore`, and
`ExperimentSource` — each read their slice from this one response (one
round-trip, one cache):

```json
{
  "flags": {},
  "versionPolicy": {
    "minVersion": null,
    "latestVersion": null,
    "hardBlockBelow": null,
    "softBlockBelow": null,
    "storeUrl": null,
    "message": null
  },
  "experiments": {},
  "revision": "1"
}
```

The response carries `ETag: "1"`. Send `If-None-Match: "1"` (or `?rev=1`) to get
a `304 Not Modified`. Bump `revision` in `lib/routes/remote_config.dart` when the
served payload changes — the `ETag` is derived from it.

## Adding a route group

Every backend contract is its own module under `lib/routes/<feature>.dart`
exposing a top-level `void registerRoutes(Router router)`. To add a group:

1. Create `lib/routes/<feature>.dart` with a `registerRoutes` that mounts its
   handlers onto the passed `Router`.
2. In `lib/server.dart`, import it with a prefix and append
   `<feature>.registerRoutes` to the `_registrars` list.

One import + one line — that is the whole wiring surface for a new group.

All C9 backend contract groups are shipped: `auth`, `cache`, `crashes`,
`events`, `feedback`, `notifications` (token registration only), `otp`, and
`remote-config`. Add a new group only when a new feature's optional real impl
needs a live endpoint.

## Develop

```
cd tools/test_server
dart pub get
dart analyze
dart test
```
