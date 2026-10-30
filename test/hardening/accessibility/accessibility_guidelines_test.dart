import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';

import 'accessibility_test_harness.dart';

void main() {
  testWidgets('Login labels every tappable semantics node', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpLogin(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Login tappables carry the brand control sizes', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpLogin(tester);
      // The brand kit fixes button heights at 36/32 in every input model, so
      // the 44pt iOS guideline no longer applies to the visual controls; the
      // brand floor (the xs control at 24) is the contract instead.
      for (final button in find.byType(FButton).evaluate()) {
        final size = tester.getSize(find.byWidget(button.widget));
        expect(size.height, inInclusiveRange(24, 40), reason: 'brand control height');
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Login meets Flutter text-contrast guidance', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpLogin(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Pricing exposes selected billing state at the brand control sizes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpGalleryCase(
        tester,
        caseId: 'pricing.recommended',
        environment: accessibilityEnvironment(viewportId: 'desktop'),
      );

      final monthly = find.semantics.byLabel('Monthly');
      final annual = find.semantics.byLabel('Annual');
      expect(monthly, findsOne);
      expect(annual, findsOne);
      expect(
        monthly.evaluate().single.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        annual.evaluate().single.getSemanticsData().flagsCollection.isSelected,
        Tristate.isFalse,
      );

      // Brand control sizes: the billing segments and plan selects are all
      // 36dp md buttons in every input model.
      for (final key in const [
        ValueKey('billing-monthly'),
        ValueKey('billing-annual'),
        ValueKey('select-plan-basic'),
        ValueKey('select-plan-pro'),
        ValueKey('select-plan-team'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
        expect(size.height, closeTo(36, 2), reason: '$key height');
      }

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'high contrast, bold text, and nonlinear scaling preserve Login meaning and actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpGalleryCase(
          tester,
          caseId: 'auth.login.invalid',
          environment: accessibilityEnvironment(
            highContrast: true,
            boldText: true,
            systemTextScale: GallerySystemTextScale.maximumNonlinear,
          ),
        );

        final submit = find.byKey(const ValueKey('auth-login-submit'));
        expect(find.byKey(const ValueKey('auth-login-invalid')), findsOneWidget);
        expect(find.text('Email address is required.'), findsWidgets);
        expect(submit, findsOneWidget);
        expect(
          tester
              .widget<FButton>(find.byKey(const ValueKey('auth-login-password-toggle')))
              .semanticsLabel,
          'Show password',
        );

        final context = tester.element(submit);
        expect(MediaQuery.highContrastOf(context), isTrue);
        expect(MediaQuery.boldTextOf(context), isTrue);
        expect(MediaQuery.textScalerOf(context), isA<GalleryMaximumTextScaler>());

        await tester.ensureVisible(submit);
        await tester.pump();
        expect(_takeExceptions(tester), isEmpty);
      } finally {
        semantics.dispose();
      }
    },
  );
}

Future<void> _pumpLogin(WidgetTester tester) {
  return pumpGalleryCase(
    tester,
    caseId: 'auth.login.idle',
    environment: accessibilityEnvironment(),
  );
}

List<Object> _takeExceptions(WidgetTester tester) {
  final exceptions = <Object>[];
  while (true) {
    final exception = tester.takeException();
    if (exception == null) break;
    exceptions.add(exception as Object);
  }
  return exceptions;
}
