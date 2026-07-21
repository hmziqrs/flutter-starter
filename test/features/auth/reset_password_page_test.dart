import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/reset_password_form_value.dart';
import 'package:starter/features/auth/reset_password_page.dart';
import 'package:starter/features/auth/reset_password_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';

import 'auth_test_harness.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('keyboard submit preserves both password values exactly', (tester) async {
    ResetPasswordFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(home: _page(onSubmit: (value) => submitted = value)),
    );
    await _enterPasswords(tester, ' Password1 ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted?.newPassword, ' Password1 ');
    expect(submitted?.confirmPassword, ' Password1 ');
  });

  testWidgets('validates and focuses password fields in visual order', (tester) async {
    setAuthTestViewport(tester, const Size(390, 560));
    await tester.pumpWidget(authTestApp(home: _page()));
    await tapAuthControl(tester, 'auth-reset-password-submit');
    expect(_editable(tester, 'auth-reset-password-new').focusNode.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('auth-reset-password-new')),
      'Password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-reset-password-confirm')),
      'Different1',
    );
    await tapAuthControl(tester, 'auth-reset-password-submit');
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(_editable(tester, 'auth-reset-password-confirm').focusNode.hasFocus, isTrue);
  });

  testWidgets('password reveal, callback loading, and login callback work', (tester) async {
    final completer = Completer<void>();
    var loginCount = 0;
    await tester.pumpWidget(
      authTestApp(
        home: _page(
          onSubmit: (_) => completer.future,
          onLogin: () => loginCount += 1,
        ),
      ),
    );
    await _enterPasswords(tester, 'Password1');
    expect(_editable(tester, 'auth-reset-password-new').obscureText, isTrue);
    await tapAuthControl(tester, 'auth-reset-password-new-toggle');
    expect(_editable(tester, 'auth-reset-password-new').obscureText, isFalse);

    await tapAuthControl(tester, 'auth-reset-password-submit');
    expect(find.text('Updating password'), findsOneWidget);
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('auth-reset-password-submit'))).onPress,
      isNull,
    );
    completer.complete();
    await tester.pump();
    await tapAuthControl(tester, 'auth-reset-password-login');
    expect(loginCount, 1);
  });

  testWidgets('renders all deterministic reset states', (tester) async {
    final cases = <(ResetPasswordPresentationState, String?)>[
      (const ResetPasswordPresentationState(), null),
      (const ResetPasswordPresentationState.focused(), null),
      (const ResetPasswordPresentationState.invalid(), 'auth-reset-password-invalid'),
      (const ResetPasswordPresentationState.submitting(), null),
      (
        const ResetPasswordPresentationState.fieldFailure(),
        'auth-reset-password-field-failure',
      ),
      (
        const ResetPasswordPresentationState.globalFailure(),
        'auth-reset-password-global-failure',
      ),
      (const ResetPasswordPresentationState.success(), 'auth-reset-password-success'),
    ];

    for (final (presentation, alertKey) in cases) {
      await tester.pumpWidget(authTestApp(home: _page(presentation: presentation)));
      await tester.pump();
      if (alertKey == null) {
        expect(find.byType(FAlert), findsNothing);
      } else {
        expect(find.byKey(ValueKey(alertKey)), findsOneWidget);
      }
      if (presentation.status == ResetPasswordPresentationStatus.submitting) {
        expect(find.text('Updating password'), findsOneWidget);
      }
      if (presentation.status == ResetPasswordPresentationStatus.focused) {
        expect(_editable(tester, 'auth-reset-password-new').focusNode.hasFocus, isTrue);
      }
    }
  });

  testWidgets('secret field values survive adaptive resize', (tester) async {
    setAuthTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      authTestApp(home: _page(key: const ValueKey('reset-under-test'))),
    );
    await _enterPasswords(tester, 'Password1');
    tester.view.physicalSize = const Size(1200, 844);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_editable(tester, 'auth-reset-password-new').controller.text, 'Password1');
    expect(find.byKey(const ValueKey('auth-reset-password-layout-expanded')), findsOneWidget);
  });
}

ResetPasswordPage _page({
  Key? key,
  ResetPasswordSubmitCallback? onSubmit,
  VoidCallback? onLogin,
  ResetPasswordPresentationState presentation = const ResetPasswordPresentationState(),
}) {
  return ResetPasswordPage(
    key: key,
    presentation: presentation,
    onSubmit: onSubmit ?? (_) {},
    onLogin: onLogin ?? () {},
  );
}

Future<void> _enterPasswords(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(const ValueKey('auth-reset-password-new')), value);
  await tester.enterText(find.byKey(const ValueKey('auth-reset-password-confirm')), value);
}

EditableText _editable(WidgetTester tester, String valueKey) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(ValueKey(valueKey)),
      matching: find.byType(EditableText),
    ),
  );
}
