import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Handwritten Riverpod provider for the [SecureStore] port.
///
/// Mirrors `settingsRepositoryProvider`: it throws a [StateError] until the
/// composition root overrides it with a concrete adapter (the production
/// `FlutterSecureStorageStore`, constructed in `AppDependencies.production`).
/// The override is wired in `lib/app/app.dart` as a peer of
/// `settingsRepositoryProvider`.
final secureStoreProvider = Provider<SecureStore>(
  (ref) => throw StateError('SecureStore must be overridden at the composition root.'),
);
