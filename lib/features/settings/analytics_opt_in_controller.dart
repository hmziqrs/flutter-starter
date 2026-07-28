import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

/// Cold-start seed for the analytics opt-in flag. Pre-loaded in
/// `AppDependencies.production` (a single [SecureStore] read of
/// [analyticsOptInKey]) and overridden at the [ProviderScope] — mirrors
/// `initialSettingsProvider`. Pre-loading lets the controller resolve
/// synchronously to the persisted value on the first frame.
final initialAnalyticsOptInProvider = Provider<bool>((ref) => false);

/// Handwritten Riverpod `Notifier<bool>` for the analytics opt-in toggle.
///
/// Backed by a thin [SecureStore] wrapper over the single [analyticsOptInKey]
/// (C4: SecureStore owns every secret / sensitive preference). This is **not**
/// a field on `SettingsState` — `SettingsState` keys are 1:1 with the plaintext
/// `SettingsStore` via `SettingsRepository`, and a SecureStore-persisted,
/// sensitive preference must stay off that surface (the settings boundary).
///
/// The SettingsPage renders the toggle by watching this controller, not
/// `settingsControllerProvider`. The real [AnalyticsClient] consults the same
/// key on every emit; the Noop default ignores it. No codegen.
final analyticsOptInControllerProvider = NotifierProvider<AnalyticsOptInController, bool>(
  AnalyticsOptInController.new,
);

final class AnalyticsOptInController extends Notifier<bool> {
  SecureStore get _store => ref.read(secureStoreProvider);

  @override
  bool build() => ref.watch(initialAnalyticsOptInProvider);

  /// Optimistically persists [value] and updates live state. On persistence
  /// failure the state rolls back to its previous value and the error rethrows
  /// so the SettingsPage can surface `common.notConnected` honestly (guardrail
  /// 13: never fake success). Mirrors `SettingsController._replace`.
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

  /// Flips the current opt-in. Fire-and-forget at the call site; the toggle UI
  /// surfaces failure via [setOptIn]'s rethrow path.
  Future<void> toggle() => setOptIn(value: !state);
}
