import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/register_form_value.dart';
import 'package:starter/features/auth/register_page.dart';
import 'package:starter/features/auth/register_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

import 'auth_test_harness.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('submits typed values with email-only boundary normalization', (tester) async {
    setAuthTestViewport(tester, const Size(800, 1200));
    RegisterFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(home: _register(onSubmit: (value) => submitted = value)),
    );
    await _enterValidRegistration(tester, password: ' Password1 ');
    await tester.ensureVisible(find.byKey(const ValueKey('auth-register-accept-terms')));
    await tapAuthControl(tester, 'auth-register-accept-terms');
    await tapAuthControl(tester, 'auth-register-submit');
    await tester.pump();

    expect(submitted?.displayName, 'Person Name');
    expect(submitted?.email, 'person@example.com');
    expect(submitted?.password, ' Password1 ');
    expect(submitted?.confirmPassword, ' Password1 ');
    expect(submitted?.acceptTerms, isTrue);
  });

  testWidgets('focuses and reveals the first invalid field in explicit order', (tester) async {
    setAuthTestViewport(tester, const Size(390, 520));
    await tester.pumpWidget(authTestApp(home: _register()));

    await tapAuthControl(tester, 'auth-register-submit');
    await tester.pumpAndSettle();
    expect(_editable(tester, 'auth-register-display-name').focusNode.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('auth-register-display-name')),
      'Person Name',
    );
    await tapAuthControl(tester, 'auth-register-submit');
    await tester.pumpAndSettle();
    expect(_editable(tester, 'auth-register-email').focusNode.hasFocus, isTrue);
  });

  testWidgets('validates confirmation then focuses the required terms control', (tester) async {
    setAuthTestViewport(tester, const Size(390, 650));
    await tester.pumpWidget(authTestApp(home: _register()));
    await _enterValidRegistration(tester, confirmPassword: 'Different1');
    await tester.ensureVisible(find.byKey(const ValueKey('auth-register-submit')));
    await tapAuthControl(tester, 'auth-register-submit');
    await tester.pumpAndSettle();

    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(_editable(tester, 'auth-register-confirm-password').focusNode.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('auth-register-confirm-password')),
      'Password1',
    );
    await tapAuthControl(tester, 'auth-register-submit');
    await tester.pumpAndSettle();

    final terms = tester.widget<FCheckbox>(
      find.byKey(const ValueKey('auth-register-accept-terms')),
    );
    expect(terms.focusNode?.hasFocus, isTrue);
    expect(find.text('Accept the terms and privacy preview to continue.'), findsOneWidget);
  });

  testWidgets('keyboard submission, reveal, and autofill policy are explicit', (tester) async {
    setAuthTestViewport(tester, const Size(800, 1200));
    RegisterFormValue? submitted;
    await tester.pumpWidget(
      authTestApp(home: _register(onSubmit: (value) => submitted = value)),
    );
    await _enterValidRegistration(tester);
    await tapAuthControl(tester, 'auth-register-accept-terms');

    expect(
      _editable(tester, 'auth-register-password').autofillHints,
      contains(AutofillHints.newPassword),
    );
    expect(_editable(tester, 'auth-register-password').obscureText, isTrue);
    await tapAuthControl(tester, 'auth-register-password-toggle');
    await tester.pump();
    expect(_editable(tester, 'auth-register-password').obscureText, isFalse);

    await tapAuthControl(tester, 'auth-register-confirm-password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submitted?.email, 'person@example.com');
  });

  testWidgets('legal controls invoke their localized callbacks', (tester) async {
    setAuthTestViewport(tester, const Size(800, 1200));
    var termsOpened = 0;
    var privacyOpened = 0;
    await tester.pumpWidget(
      authTestApp(
        home: _register(
          onOpenTerms: () => termsOpened += 1,
          onOpenPrivacy: () => privacyOpened += 1,
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const ValueKey('auth-register-open-terms')));
    await tapAuthControl(tester, 'auth-register-open-terms');
    await tapAuthControl(tester, 'auth-register-open-privacy');
    expect(termsOpened, 1);
    expect(privacyOpened, 1);
    expect(find.text('Review terms'), findsOneWidget);
    expect(find.text('Review privacy'), findsOneWidget);
  });

  testWidgets('disables duplicate registration while submit is in flight', (tester) async {
    setAuthTestViewport(tester, const Size(800, 1200));
    final completer = Completer<void>();
    await tester.pumpWidget(
      authTestApp(home: _register(onSubmit: (_) => completer.future)),
    );
    await _enterValidRegistration(tester);
    await tapAuthControl(tester, 'auth-register-accept-terms');
    await tapAuthControl(tester, 'auth-register-submit');
    await tester.pump();

    final button = tester.widget<FButton>(find.byKey(const ValueKey('auth-register-submit')));
    expect(button.onPress, isNull);
    expect(find.text('Creating account'), findsOneWidget);

    completer.complete();
    await tester.pump();
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('auth-register-submit'))).onPress,
      isNotNull,
    );
  });

  testWidgets('TV submission retains focus and blocks duplicate registration', (
    tester,
  ) async {
    final completer = Completer<void>();
    var submitCount = 0;
    setAuthTestViewport(tester, const Size(1920, 1080));
    await tester.pumpWidget(
      authTestApp(
        presentationPolicy: const AppPresentationPolicy(
          viewingEnvironment: AppViewingEnvironment.tenFoot,
          interactionPolicy: AppInteractionPolicy.remote,
        ),
        home: _register(
          onSubmit: (_) {
            submitCount += 1;
            return completer.future;
          },
        ),
      ),
    );
    await _enterValidTvRegistration(tester);
    await tapAuthControl(tester, 'auth-register-accept-terms');
    await tapAuthControl(tester, 'auth-register-submit');

    expect(
      _focusIsWithin(tester, 'auth-register-submit'),
      isTrue,
      reason: FocusManager.instance.primaryFocus?.toStringDeep(),
    );
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('auth-register-submit'))).onPress,
      isNotNull,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(submitCount, 1);

    completer.complete();
    await tester.pump();
  });

  testWidgets('renders every deterministic registration fixture', (tester) async {
    final cases = <(RegisterPresentationState, String?)>[
      (const RegisterPresentationState(), null),
      (const RegisterPresentationState.focused(), null),
      (const RegisterPresentationState.invalid(), 'auth-register-invalid'),
      (const RegisterPresentationState.submitting(), null),
      (const RegisterPresentationState.fieldFailure(), 'auth-register-field-failure'),
      (const RegisterPresentationState.globalFailure(), 'auth-register-global-failure'),
      (const RegisterPresentationState.success(), 'auth-register-success'),
    ];

    for (final (presentation, alertKey) in cases) {
      await tester.pumpWidget(
        authTestApp(home: _register(presentation: presentation)),
      );
      await tester.pump();
      if (alertKey == null) {
        expect(find.byType(FAlert), findsNothing);
      } else {
        expect(find.byKey(ValueKey(alertKey)), findsOneWidget);
      }
      if (presentation.status == RegisterPresentationStatus.submitting) {
        expect(find.text('Creating account'), findsOneWidget);
      }
      if (presentation.status == RegisterPresentationStatus.focused) {
        expect(_editable(tester, 'auth-register-display-name').focusNode.hasFocus, isTrue);
      }
    }
  });

  testWidgets('dirty system back requires explicit discard confirmation', (tester) async {
    setAuthTestViewport(tester, const Size(800, 1000));
    await tester.pumpWidget(
      authTestRouter(
        initialRoute: '/register',
        routes: {
          '/': (_) => const SizedBox(key: ValueKey('register-test-home')),
          '/register': (_) => _register(),
        },
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-display-name')),
      'Person Name',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-register-discard-stay')), findsOneWidget);

    await tapAuthControl(tester, 'auth-register-discard-stay');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-register-page')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapAuthControl(tester, 'auth-register-discard-confirm');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('register-test-home')), findsOneWidget);
  });

  testWidgets('retains values through global failure and adaptive resize', (tester) async {
    setAuthTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      authTestApp(home: _register(key: const ValueKey('register-under-test'))),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-display-name')),
      'Person Name',
    );

    await tester.pumpWidget(
      authTestApp(
        home: _register(
          key: const ValueKey('register-under-test'),
          presentation: const RegisterPresentationState.globalFailure(),
        ),
      ),
    );
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(find.text('Person Name'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-register-layout-expanded')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-register-global-failure')), findsOneWidget);
  });
}

RegisterPage _register({
  Key? key,
  RegisterSubmitCallback? onSubmit,
  VoidCallback? onOpenTerms,
  VoidCallback? onOpenPrivacy,
  RegisterPresentationState presentation = const RegisterPresentationState(),
}) {
  return RegisterPage(
    key: key,
    presentation: presentation,
    onSubmit: onSubmit ?? (_) {},
    onLogin: () {},
    onOpenTerms: onOpenTerms ?? () {},
    onOpenPrivacy: onOpenPrivacy ?? () {},
  );
}

Future<void> _enterValidRegistration(
  WidgetTester tester, {
  String password = 'Password1',
  String? confirmPassword,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('auth-register-display-name')),
    'Person Name',
  );
  await tester.enterText(
    find.byKey(const ValueKey('auth-register-email')),
    '  person@example.com  ',
  );
  await tester.enterText(find.byKey(const ValueKey('auth-register-password')), password);
  await tester.enterText(
    find.byKey(const ValueKey('auth-register-confirm-password')),
    confirmPassword ?? password,
  );
}

Future<void> _enterValidTvRegistration(WidgetTester tester) async {
  await _enterTvField(
    tester,
    activationKey: 'auth-register-display-name-activation',
    fieldKey: 'auth-register-display-name',
    text: 'Person Name',
  );
  await _enterTvField(
    tester,
    activationKey: 'auth-register-email-activation',
    fieldKey: 'auth-register-email',
    text: 'person@example.com',
  );
  await _enterTvField(
    tester,
    activationKey: 'auth-register-password-activation',
    fieldKey: 'auth-register-password',
    text: 'Password1',
  );
  await _enterTvField(
    tester,
    activationKey: 'auth-register-confirm-password-activation',
    fieldKey: 'auth-register-confirm-password',
    text: 'Password1',
  );
}

Future<void> _enterTvField(
  WidgetTester tester, {
  required String activationKey,
  required String fieldKey,
  required String text,
}) async {
  await tapAuthControl(tester, activationKey);
  await tester.enterText(find.byKey(ValueKey(fieldKey)), text);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pump();
}

EditableText _editable(WidgetTester tester, String fieldKey) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(ValueKey(fieldKey)),
      matching: find.byType(EditableText),
    ),
  );
}

bool _focusIsWithin(WidgetTester tester, String key) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext is! Element) {
    return false;
  }
  final target = tester.element(find.byKey(ValueKey(key)));
  if (identical(focusContext, target)) {
    return true;
  }
  var found = false;
  focusContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, target)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}
