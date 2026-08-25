import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/preferences/bool_codec.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';
import 'package:starter/shared/state/optimistic_notifier.dart';

final initialAnalyticsOptInProvider = Provider<bool>((ref) => false);

final analyticsOptInControllerProvider = NotifierProvider<AnalyticsOptInController, bool>(
  AnalyticsOptInController.new,
);

final class AnalyticsOptInController extends Notifier<bool> with OptimisticNotifier<bool> {
  SecureStore get _store => ref.read(secureStoreProvider);

  @override
  bool build() => ref.watch(initialAnalyticsOptInProvider);

  Future<void> setOptIn({required bool value}) async {
    await guardRollback(value, () => _store.writeBool(analyticsOptInKey, value: value));
  }

  Future<void> toggle() => setOptIn(value: !state);
}
