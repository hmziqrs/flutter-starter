import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

/// Cold-start seed for the analytics opt-in flag, pre-loaded from
/// [SecureStore] and overridden at the [ProviderScope]; mirrors
/// `initialSettingsProvider`.
final initialAnalyticsOptInProvider = Provider<bool>((ref) => false);

/// Analytics opt-in toggle. Backed by [SecureStore] (not `SettingsState`,
/// which is plaintext-only) since this is a sensitive preference; the real
/// [AnalyticsClient] consults the same key on every emit.
final analyticsOptInControllerProvider = NotifierProvider<AnalyticsOptInController, bool>(
  AnalyticsOptInController.new,
);

final class AnalyticsOptInController extends Notifier<bool> {
  SecureStore get _store => ref.read(secureStoreProvider);

  @override
  bool build() => ref.watch(initialAnalyticsOptInProvider);

  /// Optimistic write with rollback + rethrow on failure, so the caller can
  /// surface `common.notConnected` honestly.
  Future<void> setOptIn({required bool value}) async {
    final previous = state;
    state = value;
    try {
      if (value) {
        await _store.write(analyticsOptInKey, 'true');
      } else {
        await _store.delete(analyticsOptInKey);
      }
    } on Object {
      state = previous;
      rethrow;
    }
  }

  Future<void> toggle() => setOptIn(value: !state);
}
