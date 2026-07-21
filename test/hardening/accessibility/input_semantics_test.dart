import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/login_form_value.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';

import 'accessibility_test_harness.dart';

void main() {
  testWidgets('Login traverses fields logically and submits from the keyboard', (tester) async {
    LoginFormValue? submitted;
    await pumpPreviewChild(
      tester,
      environment: accessibilityEnvironment(
        viewportId: 'desktop',
        interactionPolicy: AppInteractionPolicy.precisionPointer,
      ),
      child: LoginPage(
        onSubmit: (value) => submitted = value,
        onForgotPassword: () {},
        onRegister: () {},
      ),
    );

    final email = _editable(tester, 'auth-login-email');
    final password = _editable(tester, 'auth-login-password');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(email.focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(password.focusNode.hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(email.focusNode.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('auth-login-email')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      'Password1',
    );
    await tester.showKeyboard(find.byKey(const ValueKey('auth-login-password')));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted?.email, 'person@example.com');
  });

  testWidgets('Login retains visual field traversal order in RTL', (tester) async {
    await pumpPreviewChild(
      tester,
      environment: accessibilityEnvironment(
        viewportId: 'desktop',
        locale: AppLocale.ar,
        interactionPolicy: AppInteractionPolicy.precisionPointer,
      ),
      child: LoginPage(
        onSubmit: (_) {},
        onForgotPassword: () {},
        onRegister: () {},
      ),
    );

    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey('auth-login-form'))),
      ),
      TextDirection.rtl,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_editable(tester, 'auth-login-email').focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_editable(tester, 'auth-login-password').focusNode.hasFocus, isTrue);
  });

  testWidgets('password visibility has localized semantics before and after toggling', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpGalleryCase(
        tester,
        caseId: 'auth.login.idle',
        environment: accessibilityEnvironment(),
      );

      expect(find.semantics.byLabel('Show password'), findsOne);
      await tester.tap(find.byKey(const ValueKey('auth-login-password-toggle')));
      await tester.pump();
      expect(find.semantics.byLabel('Show password'), findsNothing);
      expect(find.semantics.byLabel('Hide password'), findsOne);
      await tester.pump(const Duration(milliseconds: 150));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('OTP is announced as one labeled text field instead of six unlabeled boxes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpPreviewChild(
        tester,
        environment: accessibilityEnvironment(),
        child: OtpPage(
          purpose: OtpPurpose.registration,
          onSubmit: (_) {},
          onResend: () {},
        ),
      );

      final textFields = find.semantics.byFlag(SemanticsFlag.isTextField);
      expect(textFields, findsOne);
      final data = textFields.evaluate().single.getSemanticsData();
      expect(data.label, 'Verification code');
      expect(data.textDirection, TextDirection.ltr);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Escape dismisses the real gallery dialog', (tester) async {
    await pumpGalleryCase(
      tester,
      caseId: 'overlays.dialog',
      environment: accessibilityEnvironment(
        viewportId: 'desktop',
        interactionPolicy: AppInteractionPolicy.precisionPointer,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('overlay-dialog-trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overlay-dialog-content')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overlay-dialog-content')), findsNothing);
  });
}

EditableText _editable(WidgetTester tester, String fieldKey) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(ValueKey(fieldKey)),
      matching: find.byType(EditableText),
    ),
  );
}
