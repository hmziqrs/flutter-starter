import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/terminal_window.dart';

void main() {
  group('AppTerminalWindow', () {
    testWidgets('stays dark even on a light page', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppTerminalWindow(
            title: 'install',
            lines: <AppTerminalLine>[
              AppTerminalLine.command('flutter pub get'),
              AppTerminalLine.note('resolving packages'),
              AppTerminalLine.step('running \u203a build'),
              AppTerminalLine.result('done in 2.1s'),
            ],
          ),
        ),
      );

      // The window re-themes itself: the inner theme is the dark one.
      final innerThemes = tester
          .widgetList<FTheme>(
            find.descendant(
              of: find.byType(AppTerminalWindow),
              matching: find.byType(FTheme),
            ),
          )
          .toList();
      expect(innerThemes, hasLength(1));
      expect(innerThemes.single.data.colors.brightness, Brightness.dark);
    });

    testWidgets('draws the four line kinds with their glyphs', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppTerminalWindow(
            title: 'install',
            lines: <AppTerminalLine>[
              AppTerminalLine.command('flutter pub get'),
              AppTerminalLine.note('resolving packages'),
              AppTerminalLine.step('running \u203a build'),
              AppTerminalLine.result('done in 2.1s'),
            ],
          ),
        ),
      );

      expect(find.byIcon(FLucideIcons.squareTerminal), findsOneWidget);
      expect(_plainText(tester), contains(r'$ flutter pub get'));
      expect(_plainText(tester), contains('# resolving packages'));
      expect(_plainText(tester), contains('\u25b8 running \u203a build'));
      expect(_plainText(tester), contains('\u2713 done in 2.1s'));
    });

    testWidgets('a step answers in green behind a muted \u203a', (tester) async {
      final brand = generated.darkTheme.brand;
      await tester.pumpWidget(
        _harness(
          child: const AppTerminalWindow(
            title: 'install',
            lines: <AppTerminalLine>[AppTerminalLine.step('Building', answer: '3 crates')],
          ),
        ),
      );

      TextSpan spanFor(String text) {
        for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
          final spans = <TextSpan>[richText.text as TextSpan];
          while (spans.isNotEmpty) {
            final span = spans.removeLast();
            if (span.text == text) {
              return span;
            }
            spans.addAll(span.children?.whereType<TextSpan>() ?? const <TextSpan>[]);
          }
        }
        fail('no span for $text');
      }

      expect(_plainText(tester), contains('\u25b8 Building \u203a 3 crates'));
      expect(spanFor('\u203a ').style!.color, generated.darkTheme.colors.mutedForeground);
      expect(spanFor('3 crates').style!.color, brand.success);
    });

    testWidgets('a key and its value split around the colon', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppTerminalWindow(
            title: 'install',
            lines: <AppTerminalLine>[AppTerminalLine.keyValue('Binary', 'target/debug/app')],
          ),
        ),
      );

      expect(_plainText(tester), contains('Binary: target/debug/app'));
    });
  });
}

String _plainText(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
  return richTexts.map((richText) => (richText.text as TextSpan).toPlainText()).join('\n');
}

Widget _harness({required Widget child, Brightness brightness = Brightness.light}) {
  final theme = brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: theme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
