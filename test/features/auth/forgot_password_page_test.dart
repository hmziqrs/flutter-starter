import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/forgot_password_form_value.dart';
import 'package:starter/features/auth/forgot_password_page.dart';
import 'package:starter/features/auth/forgot_password_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';

import 'auth_test_harness.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('trims email only at the typed submission boundary', (tester) async {
    ForgotPasswordFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(
        home: _page(onSubmit: (value) => submitted = value),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-password-email')),
      '  person@example.com  ',
    );
    await tapAuthControl(tester, 'auth-forgot-password-submit');

    expect(submitted?.email, 'person@example.com');
  });

  testWidgets('invalid submit focuses the email and Done submits valid input', (tester) async {
    ForgotPasswordFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(home: _page(onSubmit: (value) => submitted = value)),
    );
    await tapAuthControl(tester, 'auth-forgot-password-submit');

    expect(
      tester.state<FormState>(find.byType(Form)).fields.single.errorText,
      'Email address is required.',
    );
    expect(_email(tester).focusNode.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-password-email')),
      'person@example.com',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submitted?.email, 'person@example.com');
  });

  testWidgets('renders all deterministic feedback states and disables submitting', (tester) async {
    final cases = <(ForgotPasswordPresentationState, String?)>[
      (const ForgotPasswordPresentationState(), null),
      (const ForgotPasswordPresentationState.focused(), null),
      (const ForgotPasswordPresentationState.invalid(), 'auth-forgot-password-invalid'),
      (const ForgotPasswordPresentationState.submitting(), null),
      (
        const ForgotPasswordPresentationState.fieldFailure(),
        'auth-forgot-password-field-failure',
      ),
      (
        const ForgotPasswordPresentationState.globalFailure(),
        'auth-forgot-password-global-failure',
      ),
      (const ForgotPasswordPresentationState.success(), 'auth-forgot-password-success'),
    ];

    for (final (presentation, alertKey) in cases) {
      await tester.pumpWidget(authTestApp(home: _page(presentation: presentation)));
      await tester.pump();
      if (alertKey == null) {
        expect(find.byType(FAlert), findsNothing);
      } else {
        expect(find.byKey(ValueKey(alertKey)), findsOneWidget);
      }
      final button = tester.widget<FButton>(
        find.byKey(const ValueKey('auth-forgot-password-submit')),
      );
      expect(
        button.onPress,
        presentation.status == ForgotPasswordPresentationStatus.submitting ? isNull : isNotNull,
      );
      if (presentation.status == ForgotPasswordPresentationStatus.focused) {
        expect(_email(tester).focusNode.hasFocus, isTrue);
      }
    }
  });

  testWidgets('login callback works and email survives adaptive resize', (tester) async {
    setAuthTestViewport(tester, const Size(390, 844));
    var loginCount = 0;
    await tester.pumpWidget(
      authTestApp(
        home: _page(
          key: const ValueKey('forgot-under-test'),
          onLogin: () => loginCount += 1,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-password-email')),
      'person@example.com',
    );
    await tapAuthControl(tester, 'auth-forgot-password-login');
    expect(loginCount, 1);

    tester.view.physicalSize = const Size(1200, 844);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('person@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-forgot-password-layout-expanded')),
      findsOneWidget,
    );
  });
}

ForgotPasswordPage _page({
  Key? key,
  ForgotPasswordSubmitCallback? onSubmit,
  VoidCallback? onLogin,
  ForgotPasswordPresentationState presentation = const ForgotPasswordPresentationState(),
}) {
  return ForgotPasswordPage(
    key: key,
    presentation: presentation,
    onSubmit: onSubmit ?? (_) {},
    onLogin: onLogin ?? () {},
  );
}

EditableText _email(WidgetTester tester) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const ValueKey('auth-forgot-password-email')),
      matching: find.byType(EditableText),
    ),
  );
}
