import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

final initialAnalyticsOptInProvider = Provider<bool>((ref) => false);

final analyticsOptInControllerProvider = NotifierProvider<AnalyticsOptInController, bool>(
  AnalyticsOptInController.new,
);

final class AnalyticsOptInController extends Notifier<bool> {
  SecureStore get _store => ref.read(secureStoreProvider);

  @override
  bool build() => ref.watch(initialAnalyticsOptInProvider);

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
