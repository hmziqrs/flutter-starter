import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';

Future<void> resetTestSettings() async {
  final store = SharedPreferencesSettingsStore();
  for (final key in SettingsRepository.persistedKeys) {
    await store.remove(key);
  }
  await store.remove(lastRouteKey);
  await store.writeString(SettingsRepository.onboardingKey, 'true');
}

Future<void> tapVisible(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  tester.binding.focusManager.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(target);
  await pumpAppFrames(tester);
  await tester.tap(target.hitTestable());
  await pumpAppFrames(tester);
}

/// Avoids [WidgetTester.pumpAndSettle]: a focused editable or animation schedules frames forever.
Future<void> pumpAppFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
