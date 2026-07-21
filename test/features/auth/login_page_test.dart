import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/login_form_value.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';

import 'auth_test_harness.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('submits a typed value and normalizes only the email boundary', (tester) async {
    LoginFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(
        home: _login(onSubmit: (value) => submitted = value),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-login-email')),
      '  person@example.com  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      ' Password1 ',
    );
    await tapAuthControl(tester, 'auth-login-remember');
    await tapAuthControl(tester, 'auth-login-submit');
    await tester.pump();

    expect(submitted?.email, 'person@example.com');
    expect(submitted?.password, ' Password1 ');
    expect(submitted?.rememberMe, isTrue);
  });

  testWidgets('validates granularly and focuses fields in explicit visual order', (tester) async {
    setAuthTestViewport(tester, const Size(390, 520));
    await tester.pumpWidget(authTestApp(home: _login()));

    await tapAuthControl(tester, 'auth-login-submit');
    await tester.pumpAndSettle();

    expect(find.text('Email address is required.'), findsOneWidget);
    expect(_editable(tester, 'auth-login-email').focusNode.hasFocus, isTrue);

    await tester.enterText(find.byKey(const ValueKey('auth-login-email')), 'person@example.com');
    await tapAuthControl(tester, 'auth-login-submit');
    await tester.pumpAndSettle();

    expect(_editable(tester, 'auth-login-password').focusNode.hasFocus, isTrue);
  });

  testWidgets('the done keyboard action submits and password reveal is localized', (tester) async {
    LoginFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(home: _login(onSubmit: (value) => submitted = value)),
    );
    await tester.enterText(find.byKey(const ValueKey('auth-login-email')), 'person@example.com');
    await tester.enterText(find.byKey(const ValueKey('auth-login-password')), 'Password1');

    final password = _editable(tester, 'auth-login-password');
    expect(password.obscureText, isTrue);
    expect(password.autofillHints, contains(AutofillHints.password));
    expect(
      tester
          .widget<FButton>(find.byKey(const ValueKey('auth-login-password-toggle')))
          .semanticsLabel,
      'Show password',
    );

    await tapAuthControl(tester, 'auth-login-password-toggle');
    await tester.pump();
    expect(_editable(tester, 'auth-login-password').obscureText, isFalse);
    expect(
      tester
          .widget<FButton>(find.byKey(const ValueKey('auth-login-password-toggle')))
          .semanticsLabel,
      'Hide password',
    );

    await tapAuthControl(tester, 'auth-login-password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submitted?.email, 'person@example.com');
  });

  testWidgets('disables duplicate submission while the callback is in flight', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      authTestApp(home: _login(onSubmit: (_) => completer.future)),
    );
    await tester.enterText(find.byKey(const ValueKey('auth-login-email')), 'person@example.com');
    await tester.enterText(find.byKey(const ValueKey('auth-login-password')), 'Password1');
    await tapAuthControl(tester, 'auth-login-submit');
    await tester.pump();

    final button = tester.widget<FButton>(find.byKey(const ValueKey('auth-login-submit')));
    expect(button.onPress, isNull);
    expect(find.text('Signing in'), findsOneWidget);

    completer.complete();
    await tester.pump();
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('auth-login-submit'))).onPress,
      isNotNull,
    );
  });

  testWidgets('renders every deterministic presentation fixture', (tester) async {
    final cases = <(LoginPresentationState, String?)>[
      (const LoginPresentationState(), null),
      (const LoginPresentationState.focused(), null),
      (const LoginPresentationState.invalid(), 'auth-login-invalid'),
      (const LoginPresentationState.submitting(), null),
      (const LoginPresentationState.fieldFailure(), 'auth-login-field-failure'),
      (const LoginPresentationState.globalFailure(), 'auth-login-global-failure'),
      (const LoginPresentationState.success(), 'auth-login-success'),
    ];

    for (final (presentation, alertKey) in cases) {
      await tester.pumpWidget(
        authTestApp(home: _login(presentation: presentation)),
      );
      await tester.pump();
      if (alertKey == null) {
        expect(find.byType(FAlert), findsNothing);
      } else {
        expect(find.byKey(ValueKey(alertKey)), findsOneWidget);
      }
      if (presentation.status == LoginPresentationStatus.submitting) {
        expect(find.text('Signing in'), findsOneWidget);
      }
      if (presentation.status == LoginPresentationStatus.focused) {
        expect(_editable(tester, 'auth-login-email').focusNode.hasFocus, isTrue);
      }
    }
  });

  testWidgets('retains entered values through failure state and live resize', (tester) async {
    setAuthTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      authTestApp(home: _login(key: const ValueKey('login-under-test'))),
    );
    await tester.enterText(find.byKey(const ValueKey('auth-login-email')), 'person@example.com');

    await tester.pumpWidget(
      authTestApp(
        home: _login(
          key: const ValueKey('login-under-test'),
          presentation: const LoginPresentationState.globalFailure(),
        ),
      ),
    );
    tester.view.physicalSize = const Size(1200, 844);
    await tester.pumpAndSettle();

    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-login-layout-expanded')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-login-global-failure')), findsOneWidget);
  });

  testWidgets('native form reset clears values, errors, selection, and focus', (tester) async {
    await tester.pumpWidget(authTestApp(home: _login()));
    await tester.enterText(find.byKey(const ValueKey('auth-login-email')), 'invalid');
    await tester.enterText(find.byKey(const ValueKey('auth-login-password')), 'short');
    await tapAuthControl(tester, 'auth-login-remember');
    await tapAuthControl(tester, 'auth-login-submit');
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(_editable(tester, 'auth-login-email').focusNode.hasFocus, isTrue);

    tester.state<FormState>(find.byType(Form)).reset();
    await tester.pumpAndSettle();

    expect(_editable(tester, 'auth-login-email').controller.text, isEmpty);
    expect(_editable(tester, 'auth-login-password').controller.text, isEmpty);
    expect(
      tester.widget<FCheckbox>(find.byKey(const ValueKey('auth-login-remember'))).value,
      isFalse,
    );
    expect(find.text('Enter a valid email address.'), findsNothing);
    expect(_editable(tester, 'auth-login-email').focusNode.hasFocus, isFalse);
    expect(_editable(tester, 'auth-login-password').focusNode.hasFocus, isFalse);
  });

  testWidgets('password is not restored after the owning page is reconstructed', (tester) async {
    await tester.pumpWidget(
      authTestApp(home: _login(key: const ValueKey('first-login'))),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      'Password1',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      authTestApp(home: _login(key: const ValueKey('second-login'))),
    );
    await tester.pump();

    expect(_editable(tester, 'auth-login-password').controller.text, isEmpty);
  });
}

LoginPage _login({
  Key? key,
  LoginSubmitCallback? onSubmit,
  LoginPresentationState presentation = const LoginPresentationState(),
}) {
  return LoginPage(
    key: key,
    presentation: presentation,
    onSubmit: onSubmit ?? (_) {},
    onForgotPassword: () {},
    onRegister: () {},
  );
}

EditableText _editable(WidgetTester tester, String fieldKey) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(ValueKey(fieldKey)),
      matching: find.byType(EditableText),
    ),
  );
}
