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
    expect(theme.typography.body.md.fontSize, closeTo(18 * 1.6, 0.001));
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
    expect(textScaler.scale(theme.typography.body.md.fontSize!), closeTo(46.08, 0.001));
  });
}

final class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize <= 20 ? fontSize * 2 : fontSize * 1.6;

  @override
  double get textScaleFactor => 2;
}
