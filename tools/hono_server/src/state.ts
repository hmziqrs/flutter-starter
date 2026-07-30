/**
 * Tiny in-memory state shared by the dummy Hono handlers.
 *
 * The server is "dummy static": it returns canned, contract-faithful responses
 * everywhere EXCEPT where the contract itself needs a round-trip between two
 * calls (auth refresh-token rotation, feedback POST -> status, otp issue ->
 * verify). Those live here so `buildApp(state?)` can hand a fresh state to each
 * test, mirroring the in-memory tables in `tools/test_server/lib/routes/*`.
 *
 * Single-process only — no persistence across restarts, exactly like the Dart
 * test server.
 */

export interface IssuedOtp {
  attemptToken: string;
  identifier: string;
  purpose: string;
  /** The fixed valid code this dummy accepts on /verify. */
  code: string;
  /** Epoch milliseconds. */
  expiresAt: number;
  failedAttempts: number;
  /** Epoch milliseconds, or null when not locked. */
  lockedUntil: number | null;
}

export interface CacheRecord {
  data: unknown;
  etag: string;
  ttlSeconds: number;
  epoch: number;
}

export interface FeedbackRecord {
  state: string;
  acceptedAt: number;
}

/** Status of an account in the registration lifecycle. A freshly registered
 * account is `pending` until the registration OTP verifies; verify flips it to
 * `active`. Mirrors `tools/test_server/lib/accounts.dart`'s `AccountStatus`. */
export type AccountStatus = 'pending' | 'active';

/** In-memory account record. `/v1/auth/register` creates a `pending` account;
 * `/v1/otp/verify` (registration) activates it and mints a session inline. */
export interface Account {
  userId: string;
  email: string;
  password: string;
  displayName: string;
  bio: string;
  status: AccountStatus;
}

export interface ServerState {
  /** refresh-token -> userId (rotated on /v1/auth/refresh). */
  refreshTokens: Map<string, string>;
  /** feedback id -> record (POST -> /status round-trip). */
  feedback: Map<string, FeedbackRecord>;
  /** attempt_token -> issued otp (issue -> verify round-trip). */
  otpIssues: Map<string, IssuedOtp>;
  /** email -> account (register creates pending; verify activates). */
  accountsByEmail: Map<string, Account>;
  /** Primed cacheable entries (canonical `welcome` fixture included). */
  cacheEntries: Map<string, CacheRecord>;
  /** Monotonic counters so issued tokens/ids never collide in one process. */
  counters: { auth: number; otp: number; feedback: number };
}

/**
 * Build a fresh state. The canonical `welcome` cache fixture is restored so a
 * freshly started server serves at least one known key without priming —
 * mirrors `tools/test_server/lib/routes/cache.dart`.
 */
export function createState(): ServerState {
  return {
    refreshTokens: new Map(),
    feedback: new Map(),
    otpIssues: new Map(),
    accountsByEmail: new Map(),
    cacheEntries: new Map<string, CacheRecord>([
      [
        'welcome',
        {
          data: { message: 'Welcome to the starter.' },
          etag: '"welcome-1"',
          ttlSeconds: 300,
          epoch: 1,
        },
      ],
    ]),
    counters: { auth: 0, otp: 0, feedback: 0 },
  };
}
