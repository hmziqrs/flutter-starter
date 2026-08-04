class LazyFirebaseInstance<T> {
  LazyFirebaseInstance(this._factory);

  final Future<T> Function() _factory;

  T? _instance;
  bool _resolveFailed = false;

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
    } on Object {}
  }
}
