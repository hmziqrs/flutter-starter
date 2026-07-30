# starter_hono_server

A dummy static [Hono](https://hono.dev/) (TypeScript) server that implements the
**same `/v1/*` API contract** as the in-repo Dart shelf test server at
[`../test_server`](../test_server). It exists so the Flutter app's real HTTP
clients can be verified against a **JavaScript** backend in addition to the
Dart one — a cross-framework contract check.

> Like `tools/test_server`, this server is **never compiled into the app**. It
> is a dev/test fixture only. The app ships zero-backend by default (C2); this
> server gives the optional "real impl" adapters a second, framework-distinct
> live endpoint to exercise.

## Run

Primary runtime is Bun (the `dev`/`start` scripts use it); it also runs under
Node via `tsx` through `@hono/node-server`:

```sh
# Bun (preferred)
bun run src/index.ts --port 8787

# Node / tsx
npx tsx src/index.ts --port 8787

# Or via the npm scripts (Bun, default port 8787)
bun run dev
```

The port resolves from `--port` (preferred), then the `PORT` env var, then the
default `8787`. The server binds to loopback (`127.0.0.1`) and prints
`LISTENING <port>` once bound — the same readiness line `tools/test_server`
emits, so the same harness can detect either.

> The justfile exposes this as `just hono-server` (see the root `justfile`);
> `just hono-server 9000` overrides the port. `just test-server` runs the Dart
> mirror on port 8080.

## Route table

| Method | Path                                        | Status / Shape                                                       | Notes |
| ------ | ------------------------------------------- | -------------------------------------------------------------------- | ----- |
| GET    | `/healthz`                                  | `200 {ok:true}`                                                      | Liveness probe. |
| POST   | `/v1/crashes`                               | `204`                                                                | `{message, stack?, context, platform, appVersion}` -> 204; malformed -> `400 {error:'invalid json'}`. |
| POST   | `/v1/events`                                | `204`                                                                | Batched `{events:[...]}` -> 204; empty body / missing `events` -> `400`. |
| POST   | `/v1/auth/issue`                            | `200 {accessToken, refreshToken, expiresAt, userId}`                 | `{email,password}` -> tokens; bad creds -> `401`. |
| POST   | `/v1/auth/register`                         | `200 {attempt_token, expires_at, channel, dev_code}` \| `409`        | `{email,password,displayName}` -> registration OTP envelope (creates a `pending` account); duplicate email -> `409 {error:'conflict'}`. |
| POST   | `/v1/auth/refresh`                          | `200 {accessToken, refreshToken, expiresAt}`                         | `{refreshToken}` -> **rotated** token; replay of the old one -> `401`. |
| POST   | `/v1/auth/logout`                           | `204`                                                                | Idempotent; `{refreshToken?}`. |
| GET    | `/v1/remote-config`                         | `200 {flags, versionPolicy, experiments, revision}` + `ETag: "1"`    | `If-None-Match: "1"` / `?rev=1` / `*` -> `304`. |
| POST   | `/v1/otp/issue`                             | `200 {attempt_token, expires_at, channel, dev_code}`                 | `{purpose, identifier}`; `purpose` ∈ {registration, password-reset, mfa}. |
| POST   | `/v1/otp/verify`                            | `200 {valid}` \| `200 {valid,access_token,refresh_token,expires_at,user_id}` \| `409 {error:'expired'}` \| `429 {error:'locked'}` | `{attempt_token, code}`; a **registration** verify activates the pending account and mints a session inline; unknown/expired token -> 409; too many wrong codes -> 429. |
| POST   | `/v1/otp/resend`                            | `200 {attempt_token, expires_at, channel, dev_code}`                 | `{identifier, purpose}`. |
| POST   | `/v1/feedback`                              | `200 {id}`                                                           | `{message, email?, screenshotMime?, screenshotBase64?, appMetadata?}`; invalid -> `422`; screenshot too large -> `413`. |
| GET    | `/v1/feedback/:id/status`                   | `200 {state}` \| `404`                                               | Known id -> `{state:'queued'}`; unknown -> 404. |
| GET    | `/v1/cache/:key`                            | `200 {data, etag, ttlSeconds, epoch}` \| `304` \| `404`              | `If-None-Match` / `*` / `?minEpoch=<ts>` -> 304; canonical fixture at key `welcome`. |
| POST   | `/v1/notifications/register-token`          | `204`                                                                | `{token, platform, deviceId}`. |
| DELETE | `/v1/notifications/register-token/:token`   | `204`                                                                | Idempotent. |
| POST   | `/v1/notifications/permission-revoked`      | `204`                                                                | `{deviceId}`. |

`/v1/` is the uniform versioning prefix for every app-facing route, matching
`tools/test_server` (contract C9 in
[`plans/feature_roadmap/contracts.md`](../../plans/feature_roadmap/contracts.md)).

### In-memory state

The server is "dummy static": canned, contract-faithful responses everywhere
except where the contract itself needs a round-trip between two calls:

- **auth refresh-token rotation** — `/v1/auth/refresh` drops the presented
  refresh token and issues a fresh one against the same user id; replaying the
  old token yields `401`.
- **feedback round-trip** — `POST /v1/feedback` records an id; `GET
  /v1/feedback/:id/status` reports `state: 'queued'` for it.
- **otp issue -> verify** — `issue`/`resend` return a fixed `dev_code`
  (`123456`); `verify` accepts that code as valid, returns `409 expired` for an
  unknown/consumed token, and `429 locked` after the wrong-code allowance is
  exceeded (2 free attempts, then the 3rd locks — agreeing with the client
  cooldown).
- **account registration** — `POST /v1/auth/register` creates a `pending`
  account keyed by email; a successful `registration`-purpose `/v1/otp/verify`
  flips it to `active` and mints a session (`access_token`/`refresh_token`) in
  the same response, so the client is authenticated immediately. `/v1/auth/issue`
  mints tokens directly against the email-derived user id without checking the
  account (the dev login shortcut).

State lives in `src/state.ts` and is per-process; nothing persists across
restarts, exactly like the Dart test server.

### Remote-config payload

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
a `304 Not Modified`.

## Develop

```sh
cd tools/hono_server
bun install        # resolve deps
bun test           # run the contract tests (in-memory via app.request)
bun run src/index.ts --port 8787   # run the server
```

## Testing seam

`buildApp(state?)` (exported from `src/index.ts`) returns a fresh `Hono` app
over an optional in-memory `state` (a fresh one is created when omitted). The
contract tests in `test/contract.test.ts` drive it in-memory via
`app.request(...)` — no socket is bound.
