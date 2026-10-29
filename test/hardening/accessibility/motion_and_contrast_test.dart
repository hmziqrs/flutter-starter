import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

import 'accessibility_test_harness.dart';

void main() {
  testWidgets('disabled animation advances onboarding immediately', (tester) async {
    await pumpGalleryCase(
      tester,
      caseId: 'onboarding.first',
      environment: accessibilityEnvironment(animationsEnabled: false),
    );

    expect(find.byKey(const ValueKey('onboarding-progress')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.pump();

    // Progress is announced through the live region's semantics label; the
    // words are not rendered as visible page text.
    final progress = tester.firstWidget<Semantics>(
      find.byKey(const ValueKey('onboarding-progress')),
    );
    expect(progress.properties.label, contains('Step 2 of 3'));
    await tester.pump(const Duration(milliseconds: 150));
  });

  test('theme color pairs meet WCAG AA and active-indicator contrast', () {
    for (final brightness in Brightness.values) {
      for (final accent in AppAccent.values) {
        final colors = ForuiThemeFactory.build(
          brightness: brightness,
          accent: accent,
          fontScale: 1,
          interactionPolicy: AppInteractionPolicy.touch,
        ).colors;
        final fixture = '${brightness.name}/${accent.name}';

        expect(
          _contrastRatio(colors.foreground, colors.background),
          greaterThanOrEqualTo(4.5),
          reason: '$fixture normal text',
        );
        expect(
          _contrastRatio(colors.mutedForeground, colors.background),
          greaterThanOrEqualTo(4.5),
          reason: '$fixture muted text',
        );
        expect(
          _contrastRatio(colors.primaryForeground, colors.primary),
          greaterThanOrEqualTo(4.5),
          reason: '$fixture primary button text',
        );
        expect(
          _contrastRatio(colors.destructiveForeground, colors.destructive),
          greaterThanOrEqualTo(4.5),
          reason: '$fixture destructive text',
        );
        expect(
          _contrastRatio(colors.errorForeground, colors.error),
          greaterThanOrEqualTo(4.5),
          reason: '$fixture error text',
        );
        expect(
          _contrastRatio(colors.primary, colors.background),
          greaterThanOrEqualTo(3),
          reason: '$fixture selected/focus indicator',
        );
      }
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final light = math.max(firstLuminance, secondLuminance);
  final dark = math.min(firstLuminance, secondLuminance);
  return (light + 0.05) / (dark + 0.05);
}
