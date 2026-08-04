/// Guards a synchronous storage operation, translating any failure into the
/// caller's typed exception via [failure].
///
/// Mirrors `runGuarded`'s absorb-and-react philosophy but, instead of logging,
/// hands the caught error to a [failure] factory whose return type is [Never]
/// (i.e. it always throws) — letting each store wrap the raw platform failure
/// in its own domain exception while preserving the `operation` and `key`
/// context. The `on Object` clause satisfies `avoid_catches_without_on_clauses`
/// while still catching everything (both `Exception` and `Error` subtypes).
///
/// Prefer this over an ad-hoc `try`/`on Object { throw ... }` wherever a keyed
/// store op must surface a typed, context-rich failure. For `Future`-returning
/// operations use [guardStorageOpAsync], which `await`s the action so async
/// failures are caught and translated too.
T guardStorageOp<T>({
  required String operation,
  required String key,
  required T Function() action,
  required Never Function(Object error, String operation, String key) failure,
}) {
  try {
    return action();
  } on Object catch (error) {
    failure(error, operation, key);
  }
}

/// Async counterpart to [guardStorageOp] for `Future`-returning storage ops.
///
/// `await`s [action] so that both synchronous errors raised while building the
/// future and asynchronous errors raised while completing it are routed through
/// [failure]. See [guardStorageOp] for the synchronous variant and the rationale
/// behind the typed [failure] factory.
Future<T> guardStorageOpAsync<T>({
  required String operation,
  required String key,
  required Future<T> Function() action,
  required Never Function(Object error, String operation, String key) failure,
}) async {
  try {
    return await action();
  } on Object catch (error) {
    failure(error, operation, key);
  }
}
