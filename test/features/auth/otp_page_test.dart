import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_form_value.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';

import 'auth_test_harness.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('accepts six ASCII digits, paste, and exact keyboard submission', (tester) async {
    OtpFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(home: _page(onSubmit: (value) => submitted = value)),
    );
    await tester.enterText(find.byKey(const ValueKey('auth-otp-code')), '12٣45a6');
    expect(_otpEditable(tester).controller.text, '12456');

    await tester.enterText(find.byKey(const ValueKey('auth-otp-code')), '654321');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted?.code, '654321');
    expect(find.byType(FOtpField), findsOneWidget);
    expect(_otpEditable(tester).autofillHints, contains(AutofillHints.oneTimeCode));
  });

  testWidgets('invalid and partial codes focus the native OTP field', (tester) async {
    setAuthTestViewport(tester, const Size(390, 520));
    await tester.pumpWidget(authTestApp(home: _page()));
    await tester.enterText(find.byKey(const ValueKey('auth-otp-code')), '12');
    await tapAuthControl(tester, 'auth-otp-submit');

    expect(
      tester.state<FormState>(find.byType(Form)).fields.single.errorText,
      'Enter all six digits.',
    );
    expect(_otpEditable(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('uses purpose-specific copy and keeps code logically LTR in Arabic', (tester) async {
    await tester.pumpWidget(
      authTestApp(home: _page()),
    );
    expect(find.text('Verify your registration'), findsOneWidget);

    await tester.pumpWidget(
      authTestApp(
        home: _page(
          key: const ValueKey('password-reset-purpose'),
          purpose: OtpPurpose.passwordReset,
        ),
      ),
    );
    expect(find.text('Verify your reset request'), findsOneWidget);

    await LocaleSettings.setLocale(AppLocale.ar);
    await tester.pumpWidget(
      authTestApp(
        home: _page(
          key: const ValueKey('arabic-otp'),
        ),
      ),
    );
    await tester.pump();
    expect(
      Directionality.of(tester.element(find.byKey(const ValueKey('auth-otp-form')))),
      TextDirection.rtl,
    );
    expect(
      Directionality.of(tester.element(find.byKey(const ValueKey('auth-otp-code')))),
      TextDirection.ltr,
    );
  });

  testWidgets('renders every OTP fixture with purpose-specific success', (tester) async {
    final cases = <(OtpPresentationState, String?, String)>[
      (const OtpPresentationState(), null, ''),
      (const OtpPresentationState.partial(), null, '12'),
      (const OtpPresentationState.pastedComplete(), null, '123456'),
      (const OtpPresentationState.invalid(), 'auth-otp-invalid', '000000'),
      (const OtpPresentationState.expired(), 'auth-otp-expired', '111111'),
      (const OtpPresentationState.resending(), null, ''),
      (const OtpPresentationState.submitting(), null, ''),
      (const OtpPresentationState.globalFailure(), 'auth-otp-global-failure', ''),
      (const OtpPresentationState.success(), 'auth-otp-success', ''),
    ];

    for (final (presentation, alertKey, code) in cases) {
      await tester.pumpWidget(
        authTestApp(
          home: _page(
            key: ValueKey('otp-${presentation.status.name}'),
            presentation: presentation,
          ),
        ),
      );
      await tester.pump();
      expect(_otpEditable(tester).controller.text, code);
      if (alertKey == null) {
        expect(find.byType(FAlert), findsNothing);
      } else {
        expect(find.byKey(ValueKey(alertKey)), findsOneWidget);
      }
      if (presentation.status == OtpPresentationStatus.resending) {
        expect(find.text('Resending code'), findsOneWidget);
      }
      if (presentation.status == OtpPresentationStatus.submitting) {
        expect(find.text('Verifying code'), findsOneWidget);
      }
      if (presentation.status == OtpPresentationStatus.success) {
        expect(find.text('Registration verified.'), findsOneWidget);
      }
    }
  });

  testWidgets('countdown is static and resend invokes only when available', (tester) async {
    var resendCount = 0;
    await tester.pumpWidget(
      authTestApp(
        home: _page(
          presentation: const OtpPresentationState.partial(resendSeconds: 30),
          onResend: () => resendCount += 1,
        ),
      ),
    );
    final blocked = tester.widget<FButton>(find.byKey(const ValueKey('auth-otp-resend')));
    expect(blocked.onPress, isNull);
    expect(find.text('Resend available in 30 seconds'), findsOneWidget);

    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Resend available in 30 seconds'), findsOneWidget);
    expect(resendCount, 0);

    await tester.pumpWidget(
      authTestApp(
        home: _page(
          key: const ValueKey('available-resend'),
          onResend: () => resendCount += 1,
        ),
      ),
    );
    await tapAuthControl(tester, 'auth-otp-resend');
    expect(resendCount, 1);
  });

  testWidgets('retains entered code across compact to expanded resize', (tester) async {
    setAuthTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      authTestApp(home: _page(key: const ValueKey('otp-under-test'))),
    );
    await tester.enterText(find.byKey(const ValueKey('auth-otp-code')), '123456');
    tester.view.physicalSize = const Size(1200, 844);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_otpEditable(tester).controller.text, '123456');
    expect(find.byKey(const ValueKey('auth-otp-layout-expanded')), findsOneWidget);
  });
}

OtpPage _page({
  Key? key,
  OtpPurpose purpose = OtpPurpose.registration,
  OtpSubmitCallback? onSubmit,
  OtpResendCallback? onResend,
  OtpPresentationState presentation = const OtpPresentationState(),
}) {
  return OtpPage(
    key: key,
    purpose: purpose,
    presentation: presentation,
    onSubmit: onSubmit ?? (_) {},
    onResend: onResend ?? () {},
  );
}

EditableText _otpEditable(WidgetTester tester) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const ValueKey('auth-otp-code')),
      matching: find.byType(EditableText),
    ),
  );
}
