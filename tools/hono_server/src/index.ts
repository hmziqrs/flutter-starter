/**
 * Dummy static Hono server mirroring the in-repo Dart test server's `/v1/*`
 * contract (`tools/test_server`), so the Flutter app's real HTTP clients can be
 * verified against a JS server in addition to the shelf one.
 *
 * Every route returns a canned, contract-faithful response. Minimal in-memory
 * state is kept only where the contract needs a round-trip:
 *   - `/v1/auth/refresh` rotates the presented refresh token (replay -> 401).
 *   - `/v1/feedback` returns an id; `/v1/feedback/{id}/status` reports state.
 *   - `/v1/otp/issue` returns an `attempt_token` + `dev_code`; `/v1/otp/verify`
 *     accepts that fixed valid code, returns 409 expired / 429 locked per the
 *     OTP contract.
 *
 * The server prints `LISTENING <port>` once bound (the same readiness line the
 * Dart server emits) so a test harness can detect when it is ready.
 */

import { Hono, type Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';
import { pathToFileURL } from 'node:url';
import { createState, type Account, type IssuedOtp, type ServerState } from './state.js';

const JSON_HEADERS: Record<string, string> = { 'content-type': 'application/json; charset=utf-8' };

// --- remote-config: revision drives the ETag and the ?rev=/?If-None-Match 304s.
const REMOTE_CONFIG_REVISION = '1';
const REMOTE_CONFIG_ETAG = `"${REMOTE_CONFIG_REVISION}"`;
const REMOTE_CONFIG_PAYLOAD = {
  flags: {},
  versionPolicy: {
    minVersion: null,
    latestVersion: null,
    hardBlockBelow: null,
    softBlockBelow: null,
    storeUrl: null,
    message: null,
  },
  experiments: {},
  revision: REMOTE_CONFIG_REVISION,
};

// --- otp: lifetimes agree with `tools/test_server/lib/routes/otp.dart`.
const OTP_CODE_TTL_MS = 90_000;
const OTP_FREE_ATTEMPTS_BEFORE_LOCKOUT = 2;
const OTP_LOCKED_TTL_MS = 30_000;
const FIXED_VALID_CODE = '123456';
const KNOWN_OTP_PURPOSES = new Set(['registration', 'password-reset', 'mfa']);

const KNOWN_IMAGE_MIMES = new Set(['image/png', 'image/jpeg', 'image/webp']);
const ACCESS_TTL_MS = 60 * 60 * 1000;
const MAX_SCREENSHOT_BASE64 = 2 * 1024 * 1024;
const DEFAULT_PORT = 8787;

/**
 * Build a Hono app over `state` (a fresh state is created when omitted). Each
 * test should pass its own state (or accept a fresh one) so cases are isolated.
 */
export function buildApp(state: ServerState = createState()): Hono {
  const app = new Hono();

  app.get('/healthz', (c) => c.json({ ok: true }, 200, JSON_HEADERS));

  // ---------------- crashes ----------------
  app.post('/v1/crashes', async (c) => {
    const decoded = await parseJsonObjectStrict(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    return new Response(null, { status: 204 });
  });

  // ---------------- events ----------------
  app.post('/v1/events', async (c) => {
    const decoded = await parseJsonObjectStrict(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const events = decoded['events'];
    if (!Array.isArray(events)) return jsonError(c, 400, 'invalid json');
    for (const entry of events) {
      if (typeof entry !== 'object' || entry === null || Array.isArray(entry)) {
        return jsonError(c, 400, 'invalid json');
      }
    }
    return new Response(null, { status: 204 });
  });

  // ---------------- auth ----------------
  app.post('/v1/auth/issue', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const email = decoded['email'];
    const password = decoded['password'];
    if (
      typeof email !== 'string' ||
      email.length === 0 ||
      typeof password !== 'string' ||
      password.length === 0
    ) {
      return jsonError(c, 401, 'unauthorized');
    }
    const userId = userIdFor(email);
    const refreshToken = issueToken(state, 'rt');
    state.refreshTokens.set(refreshToken, userId);
    return c.json(
      {
        accessToken: issueToken(state, 'at'),
        refreshToken,
        expiresAt: new Date(Date.now() + ACCESS_TTL_MS).toISOString(),
        userId,
      },
      200,
      JSON_HEADERS,
    );
  });

  app.post('/v1/auth/register', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const email = decoded['email'];
    const password = decoded['password'];
    const displayName = decoded['displayName'];
    if (
      typeof email !== 'string' ||
      email.length === 0 ||
      typeof password !== 'string' ||
      password.length === 0 ||
      typeof displayName !== 'string' ||
      displayName.length === 0
    ) {
      return jsonError(c, 400, 'invalid json');
    }
    // A pending OR active account for this email blocks a fresh registration —
    // the client must verify or recover instead (mirrors the Dart 409 conflict).
    if (state.accountsByEmail.has(email)) {
      return jsonError(c, 409, 'conflict');
    }
    const userId = userIdFor(email);
    const account: Account = {
      userId,
      email,
      password,
      displayName,
      bio: '',
      status: 'pending',
    };
    state.accountsByEmail.set(email, account);
    // Hand the OTP issue to the shared envelope helper so register and the
    // standalone otp routes share attempt-token / dev_code behavior (single
    // source of truth, mirroring `otp.dart`'s `issueOtpEnvelope`).
    return c.json(issueOtpEnvelope(state, 'registration', email), 200, JSON_HEADERS);
  });

  app.post('/v1/auth/refresh', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const presented = decoded['refreshToken'];
    if (typeof presented !== 'string') return jsonError(c, 401, 'unauthorized');
    const userId = state.refreshTokens.get(presented);
    if (userId === undefined) return jsonError(c, 401, 'unauthorized');
    // ROTATE: drop the presented token first so a replay yields 401.
    state.refreshTokens.delete(presented);
    const rotated = issueToken(state, 'rt');
    state.refreshTokens.set(rotated, userId);
    return c.json(
      {
        accessToken: issueToken(state, 'at'),
        refreshToken: rotated,
        expiresAt: new Date(Date.now() + ACCESS_TTL_MS).toISOString(),
      },
      200,
      JSON_HEADERS,
    );
  });

  app.post('/v1/auth/logout', async (c) => {
    // Idempotent: a missing/malformed body still yields 204.
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded !== null && typeof decoded['refreshToken'] === 'string') {
      state.refreshTokens.delete(decoded['refreshToken']);
    }
    return new Response(null, { status: 204 });
  });

  // ---------------- remote-config ----------------
  app.get('/v1/remote-config', (c) => {
    // Conditional via If-None-Match (RFC 7232). `*` always matches.
    const ifNoneMatch = c.req.header('if-none-match');
    if (ifNoneMatch === REMOTE_CONFIG_ETAG || ifNoneMatch === '*') {
      return new Response(null, { status: 304, headers: { etag: REMOTE_CONFIG_ETAG } });
    }
    // Conditional via ?rev= (mobile-friendly cache hit).
    const rev = c.req.query('rev');
    if (rev === REMOTE_CONFIG_REVISION) {
      return new Response(null, { status: 304, headers: { etag: REMOTE_CONFIG_ETAG } });
    }
    return c.json(REMOTE_CONFIG_PAYLOAD, 200, { ...JSON_HEADERS, etag: REMOTE_CONFIG_ETAG });
  });

  // ---------------- otp ----------------
  app.post('/v1/otp/issue', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const purpose = decoded['purpose'];
    const identifier = decoded['identifier'];
    if (
      typeof purpose !== 'string' ||
      !KNOWN_OTP_PURPOSES.has(purpose) ||
      typeof identifier !== 'string' ||
      identifier.length === 0
    ) {
      return jsonError(c, 400, 'invalid json');
    }
    const existing = findOtpByIdentifier(state, identifier);
    if (existing !== undefined && isLockedAt(existing, Date.now())) {
      return lockedResponse(c, existing.lockedUntil as number);
    }
    return c.json(issueOtpEnvelope(state, purpose, identifier), 200, JSON_HEADERS);
  });

  app.post('/v1/otp/verify', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const attemptToken = decoded['attempt_token'];
    const code = decoded['code'];
    if (
      typeof attemptToken !== 'string' ||
      attemptToken.length === 0 ||
      typeof code !== 'string' ||
      code.length === 0
    ) {
      return jsonError(c, 400, 'invalid json');
    }
    const issued = state.otpIssues.get(attemptToken);
    if (issued === undefined) {
      // Unknown / already-consumed token -> same UX path as a real expiry.
      return expiredResponse(c);
    }
    const now = Date.now();
    if (isLockedAt(issued, now)) return lockedResponse(c, issued.lockedUntil as number);
    if (isExpiredAt(issued, now)) {
      state.otpIssues.delete(attemptToken);
      return expiredResponse(c);
    }
    if (issued.code !== code) {
      const failed = issued.failedAttempts + 1;
      if (failed > OTP_FREE_ATTEMPTS_BEFORE_LOCKOUT) {
        const lockedUntil = now + OTP_LOCKED_TTL_MS;
        state.otpIssues.set(attemptToken, { ...issued, failedAttempts: failed, lockedUntil });
        return lockedResponse(c, lockedUntil);
      }
      state.otpIssues.set(attemptToken, { ...issued, failedAttempts: failed });
      return c.json({ valid: false }, 200, JSON_HEADERS);
    }
    // Success: consume the token so a replay yields 409 expired.
    state.otpIssues.delete(attemptToken);
    // A registration verify also activates the pending account and mints a
    // session so the client can call authenticated routes immediately. Other
    // purposes (mfa, password-reset) return the plain {valid: true} envelope.
    if (issued.purpose === 'registration') {
      const account = state.accountsByEmail.get(issued.identifier);
      if (account !== undefined && account.status === 'pending') {
        account.status = 'active';
        const refreshToken = issueToken(state, 'rt');
        state.refreshTokens.set(refreshToken, account.userId);
        return c.json(
          {
            valid: true,
            access_token: issueToken(state, 'at'),
            refresh_token: refreshToken,
            expires_at: new Date(Date.now() + ACCESS_TTL_MS).toISOString(),
            user_id: account.userId,
          },
          200,
          JSON_HEADERS,
        );
      }
    }
    return c.json({ valid: true }, 200, JSON_HEADERS);
  });

  app.post('/v1/otp/resend', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const identifier = decoded['identifier'];
    const purpose = decoded['purpose'];
    if (
      typeof identifier !== 'string' ||
      identifier.length === 0 ||
      typeof purpose !== 'string' ||
      purpose.length === 0 ||
      !KNOWN_OTP_PURPOSES.has(purpose)
    ) {
      return jsonError(c, 400, 'invalid json');
    }
    const existing = findOtpByIdentifier(state, identifier);
    if (existing !== undefined && isLockedAt(existing, Date.now())) {
      return lockedResponse(c, existing.lockedUntil as number);
    }
    return c.json(issueOtpEnvelope(state, purpose, identifier), 200, JSON_HEADERS);
  });

  // ---------------- feedback ----------------
  app.post('/v1/feedback', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 422, 'invalid feedback submission');
    const message = decoded['message'];
    if (typeof message !== 'string' || message.trim().length === 0) {
      return jsonError(c, 422, 'invalid feedback submission');
    }
    const email = decoded['email'];
    if (email !== undefined && (typeof email !== 'string' || !looksLikeEmail(email))) {
      return jsonError(c, 422, 'invalid feedback submission');
    }
    const screenshotMime = decoded['screenshotMime'];
    const screenshotBase64 = decoded['screenshotBase64'];
    if (screenshotMime !== undefined || screenshotBase64 !== undefined) {
      if (
        typeof screenshotMime !== 'string' ||
        !KNOWN_IMAGE_MIMES.has(screenshotMime) ||
        typeof screenshotBase64 !== 'string' ||
        screenshotBase64.length === 0
      ) {
        return jsonError(c, 422, 'invalid feedback submission');
      }
      if (screenshotBase64.length > MAX_SCREENSHOT_BASE64) {
        return jsonError(c, 413, 'screenshot too large');
      }
    }
    const id = issueFeedbackId(state);
    state.feedback.set(id, { state: 'queued', acceptedAt: Date.now() });
    return c.json({ id }, 200, JSON_HEADERS);
  });

  app.get('/v1/feedback/:id/status', (c) => {
    const id = c.req.param('id');
    const record = state.feedback.get(id);
    if (record === undefined) return jsonError(c, 404, 'unknown id');
    return c.json({ state: record.state }, 200, JSON_HEADERS);
  });

  // ---------------- cache ----------------
  app.get('/v1/cache/:key', (c) => {
    const key = c.req.param('key');
    // Mirror the Dart route's `[A-Za-z0-9_.\-]+` path constraint.
    if (!/^[A-Za-z0-9_.-]+$/.test(key)) {
      return jsonError(c, 404, 'unknown cache key');
    }
    const record = state.cacheEntries.get(key);
    if (record === undefined) return jsonError(c, 404, 'unknown cache key');
    const ifNoneMatch = c.req.header('if-none-match');
    if (ifNoneMatch === record.etag || ifNoneMatch === '*') {
      return new Response(null, { status: 304, headers: { etag: record.etag } });
    }
    const minEpochRaw = c.req.query('minEpoch');
    if (minEpochRaw !== undefined) {
      const minEpoch = Number.parseInt(minEpochRaw, 10);
      if (Number.isInteger(minEpoch) && record.epoch <= minEpoch) {
        return new Response(null, { status: 304, headers: { etag: record.etag } });
      }
    }
    return c.json(
      { data: record.data, etag: record.etag, ttlSeconds: record.ttlSeconds, epoch: record.epoch },
      200,
      { ...JSON_HEADERS, etag: record.etag },
    );
  });

  // ---------------- notifications ----------------
  app.post('/v1/notifications/register-token', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const token = decoded['token'];
    const platform = decoded['platform'];
    const deviceId = decoded['deviceId'];
    if (
      typeof token !== 'string' ||
      token.length === 0 ||
      typeof platform !== 'string' ||
      platform.length === 0 ||
      typeof deviceId !== 'string' ||
      deviceId.length === 0
    ) {
      return jsonError(c, 400, 'invalid json');
    }
    return new Response(null, { status: 204 });
  });

  app.delete('/v1/notifications/register-token/:token', () =>
    // Idempotent: deleting an unknown token still yields 204.
    new Response(null, { status: 204 }),
  );

  app.post('/v1/notifications/permission-revoked', async (c) => {
    const decoded = await parseJsonObjectTolerant(c);
    if (decoded === null) return jsonError(c, 400, 'invalid json');
    const deviceId = decoded['deviceId'];
    if (typeof deviceId !== 'string' || deviceId.length === 0) {
      return jsonError(c, 400, 'invalid json');
    }
    return new Response(null, { status: 204 });
  });

  return app;
}

// ----------------------------- helpers -----------------------------

/**
 * Strict JSON-object parse: an empty body is invalid (returns null), mirroring
 * `crashes.dart` / `events.dart` which call `jsonDecode` directly.
 */
async function parseJsonObjectStrict(c: Context): Promise<Record<string, unknown> | null> {
  try {
    const text = await c.req.text();
    if (text.length === 0) return null;
    const decoded: unknown = JSON.parse(text);
    if (typeof decoded !== 'object' || decoded === null || Array.isArray(decoded)) return null;
    return decoded as Record<string, unknown>;
  } catch {
    return null;
  }
}

/**
 * Tolerant JSON-object parse: an empty body yields `{}`, mirroring the `_decode`
 * helper in `auth.dart` / `otp.dart` / `feedback.dart` / `notifications.dart`.
 */
async function parseJsonObjectTolerant(c: Context): Promise<Record<string, unknown> | null> {
  try {
    const text = await c.req.text();
    if (text.length === 0) return {};
    const decoded: unknown = JSON.parse(text);
    if (typeof decoded !== 'object' || decoded === null || Array.isArray(decoded)) return null;
    return decoded as Record<string, unknown>;
  } catch {
    return null;
  }
}

function jsonError(c: Context, status: ContentfulStatusCode, message: string): Response {
  return c.json({ error: message }, status, JSON_HEADERS);
}

function issueToken(state: ServerState, prefix: string): string {
  state.counters.auth += 1;
  // `prefix-<micros>-<counter>` — micros approximated from Date.now()*1000 so
  // the shape mirrors the Dart `prefix-${micros}-$counter` token.
  return `${prefix}-${Date.now() * 1000}-${state.counters.auth}`;
}

function issueOtpToken(state: ServerState): string {
  state.counters.otp += 1;
  return `ot-${Date.now() * 1000}-${state.counters.otp}`;
}

function issueFeedbackId(state: ServerState): string {
  state.counters.feedback += 1;
  return `fb-${Date.now() * 1000}-${state.counters.feedback}`;
}

/** Derives a stable user id from the email, mirroring Dart's `user-<hash36>`. */
function userIdFor(email: string): string {
  let h = 0;
  for (let i = 0; i < email.length; i++) {
    h = (Math.imul(31, h) + email.charCodeAt(i)) | 0;
  }
  return `user-${(h >>> 0).toString(36)}`;
}

function isExpiredAt(o: IssuedOtp, now: number): boolean {
  return now >= o.expiresAt;
}

function isLockedAt(o: IssuedOtp, now: number): boolean {
  return o.lockedUntil !== null && now < o.lockedUntil;
}

function findOtpByIdentifier(state: ServerState, identifier: string): IssuedOtp | undefined {
  for (const issued of state.otpIssues.values()) {
    if (issued.identifier === identifier) return issued;
  }
  return undefined;
}

/** Store an issued otp and drop any prior outstanding issue for the identifier. */
function storeOtp(state: ServerState, otp: IssuedOtp): void {
  for (const [key, value] of state.otpIssues) {
    if (key !== otp.attemptToken && value.identifier === otp.identifier) {
      state.otpIssues.delete(key);
    }
  }
  state.otpIssues.set(otp.attemptToken, otp);
}

/**
 * Single source of truth for issuing an OTP envelope (snake_case). Stores the
 * issued otp (dropping any prior outstanding issue for the identifier) and is
 * reused by `/v1/otp/issue`, `/v1/otp/resend`, and `/v1/auth/register` —
 * mirroring `tools/test_server/lib/routes/otp.dart`'s `issueOtpEnvelope`.
 */
function issueOtpEnvelope(
  state: ServerState,
  purpose: string,
  identifier: string,
): { attempt_token: string; expires_at: string; channel: string; dev_code: string } {
  const attemptToken = issueOtpToken(state);
  const expiresAt = Date.now() + OTP_CODE_TTL_MS;
  storeOtp(state, {
    attemptToken,
    identifier,
    purpose,
    code: FIXED_VALID_CODE,
    expiresAt,
    failedAttempts: 0,
    lockedUntil: null,
  });
  return {
    attempt_token: attemptToken,
    expires_at: new Date(expiresAt).toISOString(),
    channel: 'sms',
    // Dummy affordance: always surface the fixed code so a test/E2E driver can
    // read it without a real channel (mirrors the Dart `dev_code` affordance
    // under X-Api-Key: dev, simplified for the cross-framework dummy).
    dev_code: FIXED_VALID_CODE,
  };
}

function expiredResponse(c: Context): Response {
  return c.json({ error: 'expired' }, 409, JSON_HEADERS);
}

function lockedResponse(c: Context, lockedUntil: number): Response {
  const retryAfter = Math.max(0, Math.ceil((lockedUntil - Date.now()) / 1000));
  return c.json({ error: 'locked', retry_after_seconds: retryAfter }, 429, JSON_HEADERS);
}

function looksLikeEmail(value: string): boolean {
  const at = value.indexOf('@');
  if (at <= 0) return false;
  const dot = value.lastIndexOf('.');
  return dot > at + 1 && dot < value.length - 1;
}

// ----------------------------- entry point -----------------------------

/** Default app instance for `import`-based consumers and ad-hoc smoke runs. */
export const app = buildApp();

/**
 * Resolve the listen port from `--port` (preferred), then `PORT` env, then the
 * default. Mirrors `tools/test_server/bin/server.dart`'s `_resolvePort`.
 */
export function resolvePort(
  argv: readonly string[] = process.argv,
  env: NodeJS.ProcessEnv = process.env,
  defaultPort = DEFAULT_PORT,
): number {
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const flagEq = '--port=';
    if (arg.startsWith(flagEq)) {
      const parsed = Number.parseInt(arg.slice(flagEq.length), 10);
      if (Number.isInteger(parsed)) return parsed;
    } else if (arg === '--port' && i + 1 < argv.length) {
      const parsed = Number.parseInt(argv[i + 1]!, 10);
      if (Number.isInteger(parsed)) return parsed;
    }
  }
  const envPort = env['PORT'];
  if (envPort !== undefined) {
    const parsed = Number.parseInt(envPort, 10);
    if (Number.isInteger(parsed)) return parsed;
  }
  return defaultPort;
}

async function main(): Promise<void> {
  const port = resolvePort();
  const server = buildApp();
  if (typeof Bun !== 'undefined') {
    Bun.serve({ port, hostname: '127.0.0.1', fetch: server.fetch });
  } else {
    const { serve } = await import('@hono/node-server');
    serve({ fetch: server.fetch, port, hostname: '127.0.0.1' });
  }
  console.log(`LISTENING ${port}`);
}

// Run only when this file is the entry point (so tests can import buildApp
// without accidentally binding a port).
const meta = import.meta as { main?: boolean; url: string };
const isMain =
  typeof Bun !== 'undefined'
    ? meta.main === true
    : meta.url === pathToFileURL(process.argv[1] ?? '').href;

if (isMain) {
  await main();
}
