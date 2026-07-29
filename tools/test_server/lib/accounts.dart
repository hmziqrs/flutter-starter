/// Shared in-memory state for the auth/OTP/profile route groups.
///
/// The registration flow spans three route modules: `auth` creates a pending
/// account, `otp` verifies the registration code and activates it, and
/// `profile` serves the authenticated user. Those modules cooperate through the
/// tables exposed here rather than reaching into each other's private state.
///
/// Single-process test server only — nothing here is persisted, and the tables
/// are plain maps with no concurrent-access guards (the server is
/// single-threaded under `shelf_io`).
library;

/// Lifetime of an issued access token, mirrored from a typical backend policy.
/// Long enough to exercise foreground-refresh tests, short enough to make the
/// "expired while backgrounded" path deterministic. Shapes only the `expiresAt`
/// timestamp returned to the client; the server does not expire access tokens
/// on its own (the test server is short-lived).
const Duration accessTtl = Duration(hours: 1);

/// Status of an account in the registration lifecycle. A freshly registered
/// account is [pending] until the registration OTP verifies; verify flips it to
/// [active]. `/v1/auth/issue` (the dev login shortcut) mints session tokens
/// directly against a derived user id without creating an account.
enum AccountStatus { pending, active }

/// In-memory account record.
///
/// [displayName] and [bio] are mutable: `PUT /v1/profile` updates them in
/// place. [email] and [userId] are fixed for the account's lifetime. [password]
/// is stored only so a future password-check could compare against it; the
/// current contract does not re-verify it.
final class Account {
  Account({
    required this.userId,
    required this.email,
    required this.password,
    required this.displayName,
    required this.bio,
    required this.status,
  });

  final String userId;
  final String email;
  final String password;
  String displayName;
  String bio;
  AccountStatus status;
}

/// Accounts keyed two ways for O(1) lookup from either an email (registration,
/// profile-by-email) or a user id (token -> user resolution).
final Map<String, Account> _accountsByEmail = <String, Account>{};
final Map<String, Account> _accountsByUserId = <String, Account>{};

Account? findAccountByEmail(String email) => _accountsByEmail[email];

Account? findAccountByUserId(String userId) => _accountsByUserId[userId];

/// True if an account (pending OR active) already exists for [email]. Used by
/// `/v1/auth/register` to enforce the conflict rule.
bool accountExists(String email) => _accountsByEmail.containsKey(email);

/// Derives a stable user id from the submitted email so every path that
/// resolves an email to an identity (login, registration, profile) agrees on
/// the same id. The hash is deterministic within a process; it does not need to
/// be cryptographically unique, only stable.
String userIdForEmail(String email) => 'user-${email.hashCode.toRadixString(36)}';

/// Creates a [pending] account for [email] and indexes it both ways. Throws if
/// an account already exists for the email — callers must check
/// [accountExists] first and surface a 409 themselves.
Account createPendingAccount({
  required String email,
  required String password,
  required String displayName,
}) {
  final userId = userIdForEmail(email);
  final account = Account(
    userId: userId,
    email: email,
    password: password,
    displayName: displayName,
    bio: '',
    status: AccountStatus.pending,
  );
  _accountsByEmail[email] = account;
  _accountsByUserId[userId] = account;
  return account;
}

/// Flips [account] to [AccountStatus.active]. Called by OTP verify when a
/// registration code checks out.
void activateAccount(Account account) {
  account.status = AccountStatus.active;
}

// --- Token tables -----------------------------------------------------------

/// Monotonic counter combined with a microsecond timestamp so tokens never
/// collide within a single server process (the in-memory tables key on the
/// literal string).
int _counter = 0;

String _issueToken(String prefix) {
  _counter += 1;
  return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_counter';
}

/// access token -> user id. Every issued access token is registered here so
/// `/v1/profile` can validate a Bearer token in O(1).
final Map<String, String> _accessTokens = <String, String>{};

/// refresh token -> user id. Rotated on `/v1/auth/refresh`: the presented token
/// is removed and a fresh one is issued against the same user id, so presenting
/// the old token a second time yields 401.
final Map<String, String> _refreshTokens = <String, String>{};

/// Mints and stores an access token for [userId].
String issueAccessToken(String userId) {
  final token = _issueToken('at');
  _accessTokens[token] = userId;
  return token;
}

/// Mints and stores a refresh token for [userId].
String issueRefreshToken(String userId) {
  final token = _issueToken('rt');
  _refreshTokens[token] = userId;
  return token;
}

/// Removes [old] and issues a fresh refresh token against the same user id.
/// Returns `null` if [old] is unknown or already rotated — the caller surfaces
/// 401 in that case (the issue -> refresh -> logout contract relies on this).
({String userId, String refreshToken})? rotateRefreshToken(String old) {
  final userId = _refreshTokens.remove(old);
  if (userId == null) return null;
  final fresh = _issueToken('rt');
  _refreshTokens[fresh] = userId;
  return (userId: userId, refreshToken: fresh);
}

/// Idempotently revokes [token] (no-op if it is null or unknown). Used by
/// `/v1/auth/logout`.
void revokeRefreshToken(String? token) {
  if (token != null) _refreshTokens.remove(token);
}

String? userIdForAccessToken(String token) => _accessTokens[token];

String? userIdForRefreshToken(String token) => _refreshTokens[token];
