/**
 * Tiny in-memory state shared by the dummy Hono handlers.
 *
 * The server is "dummy static": it returns canned, contract-faithful responses
 * everywhere EXCEPT where the contract itself needs a round-trip between two
 * calls (auth refresh-token rotation, feedback POST -> status, otp issue ->
 * verify). Those live here so `buildApp(state?)` can hand a fresh state to each
 * test.
 *
 * The contract also asks the server to retain the last N crashes / events "for
 * inspection"; those bounded buffers live here too.
 *
 * Single-process only — no persistence across restarts.
 */

/** Retention caps: only the last N crashes / events are kept, so a long-running
 * dev process cannot grow without limit (crash-reporting.md / analytics.md). */
export const MAX_RETAINED_CRASHES = 20;
export const MAX_RETAINED_EVENTS = 100;

/** A crash report exactly as validated on `POST /v1/crashes`
 * (`stack` normalized to null when the client omitted it). */
export interface CrashRecord {
  message: string;
  stack: string | null;
  context: unknown;
  platform: string;
  appVersion: string;
}

/** An analytics event exactly as validated on `POST /v1/events`. */
export interface EventRecord {
  type: string;
  name: string;
  props: unknown;
  ts: string;
}

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

/** Fixture corpus served at `GET /v1/cache/search-corpus` — the head of the
 * app's bundled fixture corpus (`SearchViewData.defaults()` in
 * `lib/features/search/search_view_data.dart`), in the `[{id, title, subtitle}]`
 * wire shape `searchCorpusCodec` decodes. Exists so a run-backend wiring can
 * serve the wired corpus fetch end-to-end without priming. */
const SEARCH_CORPUS_FIXTURE: unknown = [
  {
    id: 'search-result-auth',
    title: 'Authentication',
    subtitle: 'Login, register, and password reset flows',
  },
  {
    id: 'search-result-connectivity',
    title: 'Connectivity',
    subtitle: 'Online/offline banner and network state',
  },
  {
    id: 'search-result-settings',
    title: 'Settings',
    subtitle: 'Appearance, language, and accessibility preferences',
  },
];

export interface FeedbackRecord {
  state: string;
  acceptedAt: number;
}

/** Status of an account in the registration lifecycle. A freshly registered
 * account is `pending` until the registration OTP verifies; verify flips it to
 * `active` (contract C9). */
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
  /** access-token -> userId (resolved by /v1/profile Bearer auth). */
  accessTokens: Map<string, string>;
  /** feedback id -> record (POST -> /status round-trip). */
  feedback: Map<string, FeedbackRecord>;
  /** attempt_token -> issued otp (issue -> verify round-trip). */
  otpIssues: Map<string, IssuedOtp>;
  /** email -> account (register creates pending; verify activates). */
  accountsByEmail: Map<string, Account>;
  /** Primed cacheable entries (the canonical `welcome` and `search-corpus`
   * fixtures included). */
  cacheEntries: Map<string, CacheRecord>;
  /** Bounded ring buffer of the last MAX_RETAINED_CRASHES crash reports
   * (oldest first; the final element is the newest). */
  crashes: CrashRecord[];
  /** Bounded ring buffer of the last MAX_RETAINED_EVENTS analytics events
   * (oldest first; the final element is the newest). */
  events: EventRecord[];
  /** Monotonic counters so issued tokens/ids never collide in one process. */
  counters: { auth: number; otp: number; feedback: number };
}

/**
 * Build a fresh state. The canonical `welcome` and `search-corpus` cache
 * fixtures are restored so a freshly started server serves at least the keys
 * the app's wired fetch paths ask for without priming.
 */
export function createState(): ServerState {
  return {
    refreshTokens: new Map(),
    accessTokens: new Map(),
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
      [
        'search-corpus',
        {
          // ETag / TTL match the app's conventions for this key
          // (`"search-corpus-1"`, `searchCorpusTtlSeconds` = 300).
          data: SEARCH_CORPUS_FIXTURE,
          etag: '"search-corpus-1"',
          ttlSeconds: 300,
          epoch: 1,
        },
      ],
    ]),
    counters: { auth: 0, otp: 0, feedback: 0 },
    crashes: [],
    events: [],
  };
}

/** Append `entry` to the bounded `buffer`, dropping the oldest entries past `cap`. */
function pushBounded<T>(buffer: T[], entry: T, cap: number): void {
  buffer.push(entry);
  if (buffer.length > cap) buffer.splice(0, buffer.length - cap);
}

/** Record a validated crash report into the last-N ring buffer. */
export function recordCrash(state: ServerState, crash: CrashRecord): void {
  pushBounded(state.crashes, crash, MAX_RETAINED_CRASHES);
}

/** Record a validated analytics event into the last-N ring buffer. */
export function recordEvent(state: ServerState, event: EventRecord): void {
  pushBounded(state.events, event, MAX_RETAINED_EVENTS);
}
