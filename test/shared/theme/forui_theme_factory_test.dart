import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  test('applies application scaling and bundled script fallbacks to typography', () {
    final theme = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: SettingsState.maximumFontScale,
      interactionPolicy: AppInteractionPolicy.touch,
    );

    expect(theme.typography.body.fontFamilyFallback, ForuiThemeFactory.scriptFontFamilies);
    expect(
      theme.typography.body.md.fontFamilyFallback,
      ForuiThemeFactory.scriptFontFamilies,
    );
    expect(theme.typography.body.md.fontSize, closeTo(16 * 1.6, 0.001));
    expect(theme.typography.body.md.height, 1.4);
    expect(theme.typography.display.xl3.height, 1.12);
    expect(
      theme.typography.body.md.leadingDistribution,
      TextLeadingDistribution.even,
    );
  });

  testWidgets('leaves an ambient nonlinear system TextScaler active', (tester) async {
    const textScaler = _NonlinearTextScaler();
    final theme = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: SettingsState.maximumFontScale,
      interactionPolicy: AppInteractionPolicy.touch,
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: textScaler),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Scaled copy', style: theme.typography.body.md),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('Scaled copy'));
    expect(identical(paragraph.textScaler, textScaler), isTrue);
    expect(textScaler.scale(theme.typography.body.md.fontSize!), closeTo(40.96, 0.001));
  });

  test('composes responsive and user typography scales', () {
    final theme = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: 1.2,
      responsiveFontScale: 1.1,
      interactionPolicy: AppInteractionPolicy.touch,
    );

    expect(theme.typography.body.md.fontSize, closeTo(16 * 1.2 * 1.1, 0.001));
  });

  test('balances button padding against label size and interaction target', () {
    final touch = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: 1,
      interactionPolicy: AppInteractionPolicy.touch,
    );
    final pointer = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: 1,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
    );

    expect(touch.buttonStyles.primary.md.contentStyle.constraints.minHeight, 44);
    expect(
      touch.buttonStyles.primary.md.contentStyle.padding.resolve(TextDirection.ltr).vertical,
      closeTo(14 * 0.55 * 2, 0.001),
    );
    expect(touch.buttonStyles.primary.md.contentStyle.textStyle.base.fontSize, 14);
    expect(pointer.buttonStyles.primary.md.contentStyle.constraints.minHeight, 36);
    expect(
      pointer.buttonStyles.primary.md.contentStyle.padding.resolve(TextDirection.ltr).vertical,
      closeTo(14 * 0.55 * 2, 0.001),
    );
  });
}

final class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize <= 20 ? fontSize * 2 : fontSize * 1.6;

  @override
  double get textScaleFactor => 2;
}
