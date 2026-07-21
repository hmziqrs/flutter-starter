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

  testWidgets('Login tappable semantics nodes are never smaller than 44x44', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpLogin(tester);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
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

  testWidgets('Pricing exposes selected billing state and keeps core targets at least 44x44', (
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

      for (final key in const [
        ValueKey('billing-monthly'),
        ValueKey('billing-annual'),
        ValueKey('select-plan-basic'),
        ValueKey('select-plan-pro'),
        ValueKey('select-plan-team'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
        expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
      }

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
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
