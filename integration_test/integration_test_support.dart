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
  // Seed a returning user who has completed onboarding so the production
  // composition boots straight past the onboarding redirect. Without this, a
  // freshly reset (or fresh-runner) store reads hasCompletedOnboarding=false
  // and the initial redirect lands on onboarding — the smoke/route flows,
  // which expect to start at home / route-error-home, never passed on a clean
  // runner. (The flows exercise onboarding explicitly later where needed.)
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

/// Advances a bounded number of frames for routes, overlays, and persistence.
///
/// Integration targets deliberately avoid [WidgetTester.pumpAndSettle]: a
/// focused editable or platform animation may continue scheduling frames even
/// though the application state under test is ready.
Future<void> pumpAppFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
