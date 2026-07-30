/**
 * Contract tests for the in-repo dummy Hono backend. Each test asserts the
 * status code AND JSON shape of the app's canonical `/v1/*` API contract
 * (plans/feature_roadmap/contracts.md C9), so the server stays a faithful
 * implementation for Flutter HTTP client verification.
 *
 * Tests drive the app in-memory via `app.request(...)` — no socket is bound.
 */

import { describe, it, expect } from 'bun:test';
import { buildApp } from '../src/index.js';

interface CallInit {
  method?: string;
  body?: unknown;
  headers?: Record<string, string>;
}

/** Fire an in-memory request at `app`. JSON bodies are stringified. */
async function call(app: ReturnType<typeof buildApp>, path: string, init: CallInit = {}): Promise<Response> {
  const method = init.method ?? 'GET';
  const headers = new Headers(init.headers);
  let body: string | undefined;
  if (init.body !== undefined) {
    body = JSON.stringify(init.body);
    if (!headers.has('content-type')) headers.set('content-type', 'application/json');
  }
  return app.request(path, { method, headers, body });
}

async function json(res: Response): Promise<Record<string, unknown>> {
  return (await res.json()) as Record<string, unknown>;
}

const ok = (s: number) => (res: Response) => expect(res.status).toBe(s);

describe('GET /healthz', () => {
  it('returns 200 {ok:true}', async () => {
    const app = buildApp();
    const res = await call(app, '/healthz');
    ok(200)(res);
    expect(await json(res)).toEqual({ ok: true });
  });
});

describe('POST /v1/crashes', () => {
  it('returns 204 for a valid crash report', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/crashes', {
      method: 'POST',
      body: { message: 'boom', context: {}, platform: 'macos', appVersion: '1.0.0' },
    });
    expect(res.status).toBe(204);
  });

  it('returns 400 for malformed JSON', async () => {
    const app = buildApp();
    const res = await app.request('/v1/crashes', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: 'not json',
    });
    expect(res.status).toBe(400);
    expect((await json(res))['error']).toBe('invalid json');
  });
});

describe('POST /v1/events', () => {
  it('returns 204 for a valid batch', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/events', {
      method: 'POST',
      body: { events: [{ type: 'tap', name: 'n', props: {}, ts: '2026-01-01T00:00:00Z' }] },
    });
    expect(res.status).toBe(204);
  });

  it('returns 400 on an empty body', async () => {
    const app = buildApp();
    const res = await app.request('/v1/events', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '',
    });
    expect(res.status).toBe(400);
  });

  it('returns 400 when the events list is missing', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/events', { method: 'POST', body: {} });
    expect(res.status).toBe(400);
  });
});

describe('POST /v1/auth/{issue,refresh,logout}', () => {
  it('issue -> 200 with token fields + userId', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/auth/issue', {
      method: 'POST',
      body: { email: 'a@b.com', password: 'pw' },
    });
    expect(res.status).toBe(200);
    const body = await json(res);
    expect(typeof body['accessToken']).toBe('string');
    expect(typeof body['refreshToken']).toBe('string');
    expect(typeof body['expiresAt']).toBe('string');
    expect(typeof body['userId']).toBe('string');
    expect((body['userId'] as string).startsWith('user-')).toBe(true);
  });

  it('issue -> 401 when credentials are missing', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/auth/issue', { method: 'POST', body: { email: 'a@b.com' } });
    expect(res.status).toBe(401);
  });

  it('refresh -> 200 with a rotated refresh token; replay yields 401', async () => {
    const app = buildApp();
    const issue = await call(app, '/v1/auth/issue', {
      method: 'POST',
      body: { email: 'a@b.com', password: 'pw' },
    });
    const issued = await json(issue);
    const oldRefresh = issued['refreshToken'] as string;

    const refreshRes = await call(app, '/v1/auth/refresh', {
      method: 'POST',
      body: { refreshToken: oldRefresh },
    });
    expect(refreshRes.status).toBe(200);
    const refreshed = await json(refreshRes);
    const newRefresh = refreshed['refreshToken'] as string;
    expect(newRefresh).not.toBe(oldRefresh);
    expect(typeof refreshed['accessToken']).toBe('string');
    expect(typeof refreshed['expiresAt']).toBe('string');

    // Replay of the rotated (now-invalid) token -> 401.
    const replay = await call(app, '/v1/auth/refresh', {
      method: 'POST',
      body: { refreshToken: oldRefresh },
    });
    expect(replay.status).toBe(401);
  });

  it('logout -> 204 (idempotent even with no body)', async () => {
    const app = buildApp();
    const res = await app.request('/v1/auth/logout', { method: 'POST' });
    expect(res.status).toBe(204);
  });
});

describe('POST /v1/auth/register + registration OTP verify', () => {
  it('register -> 200 with the OTP issue envelope (snake_case)', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/auth/register', {
      method: 'POST',
      body: { email: 'sam@example.com', password: 'Password1', displayName: 'Sam Rivera' },
      headers: { 'x-api-key': 'dev' },
    });
    expect(res.status).toBe(200);
    const body = await json(res);
    expect(typeof body['attempt_token']).toBe('string');
    expect(typeof body['expires_at']).toBe('string');
    expect(body['channel']).toBe('sms');
    expect(body['dev_code']).toBe('123456');
  });

  it('register -> 400 when a required field is missing', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/auth/register', {
      method: 'POST',
      body: { email: 'sam@example.com', password: 'Password1' },
    });
    expect(res.status).toBe(400);
  });

  it('register -> 409 conflict when the email is already registered', async () => {
    const app = buildApp();
    await call(app, '/v1/auth/register', {
      method: 'POST',
      body: { email: 'sam@example.com', password: 'Password1', displayName: 'Sam Rivera' },
    });
    const dup = await call(app, '/v1/auth/register', {
      method: 'POST',
      body: { email: 'sam@example.com', password: 'Password1', displayName: 'Sam Rivera' },
    });
    expect(dup.status).toBe(409);
    expect((await json(dup))['error']).toBe('conflict');
  });

  it('register -> verify activates the account, mints a session, and the refresh token rotates', async () => {
    const app = buildApp();
    const issued = await call(app, '/v1/auth/register', {
      method: 'POST',
      body: { email: 'alex@example.com', password: 'Password1', displayName: 'Alex' },
      headers: { 'x-api-key': 'dev' },
    });
    const envelope = await json(issued);

    const verify = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: envelope['attempt_token'], code: envelope['dev_code'] },
    });
    expect(verify.status).toBe(200);
    const v = await json(verify);
    expect(v['valid']).toBe(true);
    expect(typeof v['access_token']).toBe('string');
    expect(typeof v['refresh_token']).toBe('string');
    expect(typeof v['expires_at']).toBe('string');
    expect(typeof v['user_id']).toBe('string');

    // The refresh token minted at verify is usable and rotates on refresh.
    const refresh = await call(app, '/v1/auth/refresh', {
      method: 'POST',
      body: { refreshToken: v['refresh_token'] },
    });
    expect(refresh.status).toBe(200);

    // Replay of the now-rotated token -> 401.
    const replay = await call(app, '/v1/auth/refresh', {
      method: 'POST',
      body: { refreshToken: v['refresh_token'] },
    });
    expect(replay.status).toBe(401);

    // A replayed verify of the consumed attempt token -> 409 expired.
    const reverify = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: envelope['attempt_token'], code: envelope['dev_code'] },
    });
    expect(reverify.status).toBe(409);
  });

  it('verify -> {valid:true} with no tokens when the purpose is not registration', async () => {
    const app = buildApp();
    const issued = await call(app, '/v1/otp/issue', {
      method: 'POST',
      body: { purpose: 'mfa', identifier: 'mfa@example.com' },
    });
    const envelope = await json(issued);
    const verify = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: envelope['attempt_token'], code: envelope['dev_code'] },
    });
    const v = await json(verify);
    expect(v['valid']).toBe(true);
    expect(v['access_token']).toBeUndefined();
  });
});

describe('GET /v1/remote-config', () => {
  it('returns 200 with all slices + revision + etag header', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/remote-config');
    expect(res.status).toBe(200);
    expect(res.headers.get('etag')).toBe('"1"');
    const body = await json(res);
    expect(body['flags']).toEqual({});
    expect(body['experiments']).toEqual({});
    expect(body['revision']).toBe('1');
    expect(body['versionPolicy']).toEqual({
      minVersion: null,
      latestVersion: null,
      hardBlockBelow: null,
      softBlockBelow: null,
      storeUrl: null,
      message: null,
    });
  });

  it('returns 304 on matching If-None-Match', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/remote-config', { headers: { 'if-none-match': '"1"' } });
    expect(res.status).toBe(304);
    expect(res.headers.get('etag')).toBe('"1"');
  });

  it('returns 304 on matching ?rev=', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/remote-config?rev=1');
    expect(res.status).toBe(304);
  });
});

describe('POST /v1/otp/{issue,verify,resend}', () => {
  it('issue -> 200 with attempt_token + dev_code', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/otp/issue', {
      method: 'POST',
      body: { purpose: 'mfa', identifier: '+15551234567' },
    });
    expect(res.status).toBe(200);
    const body = await json(res);
    expect(typeof body['attempt_token']).toBe('string');
    expect(body['channel']).toBe('sms');
    expect(typeof body['expires_at']).toBe('string');
    expect(typeof body['dev_code']).toBe('string');
  });

  it('verify -> 200 {valid:true} for the fixed valid code', async () => {
    const app = buildApp();
    const issue = await call(app, '/v1/otp/issue', {
      method: 'POST',
      body: { purpose: 'mfa', identifier: '+15551234567' },
    });
    const issued = await json(issue);
    const verify = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: issued['attempt_token'], code: issued['dev_code'] },
    });
    expect(verify.status).toBe(200);
    expect((await json(verify))['valid']).toBe(true);
  });

  it('verify -> 409 expired for an unknown attempt_token', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: 'ot-unknown', code: '123456' },
    });
    expect(res.status).toBe(409);
    expect((await json(res))['error']).toBe('expired');
  });

  it('verify -> 429 locked after the free attempt allowance is exceeded', async () => {
    const app = buildApp();
    const issue = await call(app, '/v1/otp/issue', {
      method: 'POST',
      body: { purpose: 'mfa', identifier: '+15559999999' },
    });
    const issued = await json(issue);
    const token = issued['attempt_token'] as string;

    // freeAttemptsBeforeLockout = 2 -> first two wrong codes return {valid:false}.
    const first = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: token, code: '000000' },
    });
    expect(first.status).toBe(200);
    expect((await json(first))['valid']).toBe(false);

    const second = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: token, code: '000000' },
    });
    expect(second.status).toBe(200);
    expect((await json(second))['valid']).toBe(false);

    // The next failure locks the identifier.
    const third = await call(app, '/v1/otp/verify', {
      method: 'POST',
      body: { attempt_token: token, code: '000000' },
    });
    expect(third.status).toBe(429);
    const locked = await json(third);
    expect(locked['error']).toBe('locked');
    expect(typeof locked['retry_after_seconds']).toBe('number');
  });

  it('resend -> 200 with a fresh attempt_token', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/otp/resend', {
      method: 'POST',
      body: { identifier: '+15557777777', purpose: 'registration' },
    });
    expect(res.status).toBe(200);
    const body = await json(res);
    expect(typeof body['attempt_token']).toBe('string');
    expect(body['channel']).toBe('sms');
  });
});

describe('POST /v1/feedback + GET /v1/feedback/:id/status', () => {
  it('POST -> 200 {id}; status -> 200 {state:queued}; unknown -> 404', async () => {
    const app = buildApp();
    const submit = await call(app, '/v1/feedback', {
      method: 'POST',
      body: { message: 'hello', email: 'a@b.com' },
    });
    expect(submit.status).toBe(200);
    const id = (await json(submit))['id'] as string;
    expect(typeof id).toBe('string');

    const status = await call(app, `/v1/feedback/${id}/status`);
    expect(status.status).toBe(200);
    expect((await json(status))['state']).toBe('queued');

    const unknown = await call(app, '/v1/feedback/fb-does-not-exist/status');
    expect(unknown.status).toBe(404);
  });

  it('POST -> 422 on an empty message', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/feedback', { method: 'POST', body: { message: '   ' } });
    expect(res.status).toBe(422);
  });
});

describe('GET /v1/cache/:key', () => {
  it('known key -> 200 with {data,etag,ttlSeconds,epoch}', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/cache/welcome');
    expect(res.status).toBe(200);
    expect(res.headers.get('etag')).toBe('"welcome-1"');
    const body = await json(res);
    expect(body['data']).toEqual({ message: 'Welcome to the starter.' });
    expect(body['etag']).toBe('"welcome-1"');
    expect(typeof body['ttlSeconds']).toBe('number');
    expect(typeof body['epoch']).toBe('number');
  });

  it('unknown key -> 404', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/cache/nope');
    expect(res.status).toBe(404);
  });

  it('returns 304 on matching If-None-Match', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/cache/welcome', { headers: { 'if-none-match': '"welcome-1"' } });
    expect(res.status).toBe(304);
    expect(res.headers.get('etag')).toBe('"welcome-1"');
  });

  it('returns 304 when ?minEpoch is not strictly older than the entry', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/cache/welcome?minEpoch=1');
    expect(res.status).toBe(304);
  });
});

describe('notifications', () => {
  it('register-token -> 204', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/notifications/register-token', {
      method: 'POST',
      body: { token: 'tok-1', platform: 'apns', deviceId: 'dev-1' },
    });
    expect(res.status).toBe(204);
  });

  it('unregister-token (DELETE) -> 204', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/notifications/register-token/tok-1', { method: 'DELETE' });
    expect(res.status).toBe(204);
  });

  it('permission-revoked -> 204', async () => {
    const app = buildApp();
    const res = await call(app, '/v1/notifications/permission-revoked', {
      method: 'POST',
      body: { deviceId: 'dev-1' },
    });
    expect(res.status).toBe(204);
  });
});
