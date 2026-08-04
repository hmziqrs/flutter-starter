/// Lazily resolves and caches a Firebase singleton, surviving resolution
/// failures with a one-shot latch so subsequent callers short-circuit to null.
///
/// firebase_analytics and firebase_crashlytics previously each duplicated this
/// nullable-cache + `_resolveFailed` latch + `_resolve` pattern; they now share
/// this owner.
class LazyFirebaseInstance<T> {
  LazyFirebaseInstance(this._factory);

  final Future<T> Function() _factory;

  T? _instance;
  bool _resolveFailed = false;

  /// Resolves the cached instance, or attempts resolution once. After a
  /// resolution failure all future calls return `null` without retrying.
  Future<T?> resolve() async {
    if (_instance != null) {
      return _instance;
    }
    if (_resolveFailed) {
      return null;
    }
    try {
      return _instance = await _factory();
    } on Object {
      _resolveFailed = true;
      return null;
    }
  }

  /// Resolves the instance and, when supported and present, runs [action] with
  /// it. Returns `null` when the instance is unavailable or when [action]
  /// throws; callers that need to distinguish those cases should call [resolve]
  /// directly.
  Future<void> runIfSupported(
    Future<void> Function(T instance) action, {
    required bool supported,
  }) async {
    if (!supported) {
      return;
    }
    final instance = await resolve();
    if (instance == null) {
      return;
    }
    try {
      await action(instance);
    } on Object {
      // ignored
    }
  }
}
