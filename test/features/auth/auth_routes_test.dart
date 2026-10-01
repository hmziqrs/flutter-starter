import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/auth_routes.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

import 'auth_test_harness.dart';

const String _identifier = 'user@example.com';

class _FakeOtpRepository implements OtpRepository {
  _FakeOtpRepository({required this.expiresIn});

  final Duration expiresIn;

  OtpIssueResult _issue() => OtpIssueResult(
    expiresAt: clock.now().add(expiresIn),
    channel: OtpDeliveryChannel.sms,
    attemptToken: 'attempt-token',
  );

  @override
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  }) async => _issue();

  @override
  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  }) async => const OtpVerifyResult.invalid();

  @override
  Future<OtpIssueResult> resend({required String identifier}) async => _issue();
}

Widget _routeApp(OtpRepository repository) {
  return ProviderScope(
    overrides: [
      otpRepositoryProvider.overrideWithValue(repository),
      attemptTrackerProvider.overrideWithValue(InMemoryAttemptTracker()),
    ],
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const OtpRoutePage(purpose: OtpPurpose.mfa, identifier: _identifier),
            locale: localeData.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            builder: (context, child) => AppPresentationScope(
              policy: const AppPresentationPolicy(
                viewingEnvironment: AppViewingEnvironment.nearField,
                interactionPolicy: AppInteractionPolicy.touch,
              ),
              child: FTheme(
                data: theme,
                child: FToaster(
                  child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('route countdown ticks live and disappears on expiry', (tester) async {
    await tester.pumpWidget(_routeApp(_FakeOtpRepository(expiresIn: const Duration(seconds: 2))));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('auth-otp-countdown')), findsOneWidget);
    expect(find.text('Expires in 2 seconds'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Expires in 1 second'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-otp-expired')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('auth-otp-countdown')), findsNothing);
    expect(find.byKey(const ValueKey('auth-otp-expired')), findsOneWidget);
  });

  testWidgets('invalid verification rebuilds the page while the countdown stays live', (
    tester,
  ) async {
    await tester.pumpWidget(_routeApp(_FakeOtpRepository(expiresIn: const Duration(seconds: 30))));
    await tester.pump();
    await tester.pump();
    expect(find.text('Expires in 30 seconds'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('auth-otp-code')), '000000');
    await tapAuthControl(tester, 'auth-otp-submit');
    await tester.pump();

    expect(find.byKey(const ValueKey('auth-otp-invalid')), findsOneWidget);
    expect(find.text('Expires in 30 seconds'), findsOneWidget);
  });
}
