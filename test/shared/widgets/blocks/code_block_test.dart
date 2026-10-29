import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/code_block.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';

void main() {
  group('AppCodeBlock', () {
    testWidgets('carries the label and the copy button in a 40dp bar', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppCodeBlock(source: 'final x = 1;', label: 'main.dart', copyLabel: 'Copy'),
        ),
      );

      expect(find.text('main.dart'), findsOneWidget);
      expect(find.byType(AppCopyButton), findsOneWidget);
      // The bar is the block's 40dp header.
      final bar = tester.widget<Container>(
        find.ancestor(of: find.text('main.dart'), matching: find.byType(Container)).first,
      );
      expect(bar.constraints?.maxHeight, 40);
      // The plain pre keeps the svelte's px-4.5 py-4 air.
      final pre = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (widget) =>
                    widget is RichText &&
                    (widget.text as TextSpan).toPlainText().contains('final x = 1;'),
              ),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        pre.padding,
        const EdgeInsetsDirectional.only(start: 18, end: 18, top: 16, bottom: 16),
      );
    });

    testWidgets('ships no bar and no button when people only read', (tester) async {
      await tester.pumpWidget(_harness(child: const AppCodeBlock(source: 'final x = 1;')));

      expect(find.text('main.dart'), findsNothing);
      expect(find.byType(AppCopyButton), findsNothing);
    });

    testWidgets('floats its copy button when there is no bar', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppCodeBlock(source: 'cargo add gpui-query', copyLabel: 'Copy'),
        ),
      );

      // The button is positioned at the block's top right corner, not in a
      // bar (code-block.svelte: absolute top-1.5 right-1.5).
      final button = tester.widget<Positioned>(
        find.ancestor(of: find.byType(AppCopyButton), matching: find.byType(Positioned)),
      );
      expect(button.top, 6);
      expect(button.right, 6);
    });

    testWidgets('tabs switch the shown source and the copy text', (tester) async {
      AppCopyButton captured(WidgetTester tester) =>
          tester.widget<AppCopyButton>(find.byType(AppCopyButton));

      await tester.pumpWidget(
        _harness(
          child: const AppCodeBlock(
            copyLabel: 'Copy',
            files: <AppCodeFile>[
              AppCodeFile(label: 'Terminal', source: 'cargo add gpui-query'),
              AppCodeFile(label: 'Cargo.toml', source: 'gpui = "0.2"'),
            ],
          ),
        ),
      );

      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('Cargo.toml'), findsOneWidget);
      expect(captured(tester).text, 'cargo add gpui-query');
      expect(_plainCode(tester), contains('cargo add'));

      await tester.tap(find.text('Cargo.toml'));
      await tester.pump();

      expect(captured(tester).text, 'gpui = "0.2"');
      expect(_plainCode(tester), contains('gpui ='));
    });
  });
}

String _plainCode(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((richText) {
        final span = richText.text;
        return span is TextSpan ? span.toPlainText() : '';
      })
      .join('\n');
}

Widget _harness({required Widget child, Brightness brightness = Brightness.dark}) {
  final theme = brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: theme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
