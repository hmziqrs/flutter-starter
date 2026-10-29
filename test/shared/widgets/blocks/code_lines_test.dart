import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/code_lines.dart';

void main() {
  group('tokenizeDartLine', () {
    test('colors keywords as the primary role', () {
      expect(
        tokenizeDartLine('final x = 1;'),
        <CodeToken>[
          const CodeToken('final', CodeTokenKind.keyword),
          // Operators and the space between run muted with punctuation.
          const CodeToken(' ', CodeTokenKind.punctuation),
          const CodeToken('x', CodeTokenKind.plain),
          const CodeToken(' = ', CodeTokenKind.punctuation),
          const CodeToken('1', CodeTokenKind.number),
          const CodeToken(';', CodeTokenKind.punctuation),
        ],
      );
    });

    test('colors calls and type names as the function role', () {
      expect(
        tokenizeDartLine('makeGreeting(name)'),
        <CodeToken>[
          const CodeToken('makeGreeting', CodeTokenKind.function),
          const CodeToken('(', CodeTokenKind.punctuation),
          const CodeToken('name', CodeTokenKind.plain),
          const CodeToken(')', CodeTokenKind.punctuation),
        ],
      );
      final tokens = tokenizeDartLine('User user = User();');
      final typeNames = tokens.where((token) => token.text == 'User').toList();
      expect(typeNames, hasLength(2));
      expect(
        typeNames.every((token) => token.kind == CodeTokenKind.function),
        isTrue,
        reason: 'PascalCase names and constructor calls share the function role',
      );
    });

    test('colors strings green across their quotes', () {
      final tokens = tokenizeDartLine("greet('hi there');");
      final string = tokens.singleWhere((token) => token.kind == CodeTokenKind.string);
      expect(string.text, "'hi there'");
    });

    test('colors numbers and constants purple', () {
      for (final word in <String>['42', '3.14', '0xFF', 'true', 'false', 'null']) {
        final tokens = tokenizeDartLine(word);
        expect(tokens.single.kind, CodeTokenKind.number, reason: word);
      }
    });

    test('colors a whole comment line muted', () {
      final tokens = tokenizeDartLine('  // noted for later');
      expect(tokens, hasLength(1));
      expect(tokens.single.kind, CodeTokenKind.comment);
      expect(tokens.single.text, '  // noted for later');
    });

    test('colors an inline comment from its slashes on', () {
      final tokens = tokenizeDartLine('count++; // bump');
      expect(tokens.last.kind, CodeTokenKind.comment);
      expect(tokens.last.text, '// bump');
      expect(tokens.first.kind, CodeTokenKind.plain);
    });

    test('colors punctuation muted and keeps the rest plain', () {
      final kinds = tokenizeDartLine('a.b, c').map((token) => token.kind).toList();
      expect(kinds, everyElement(isNot(CodeTokenKind.comment)));
      final dotLine = tokenizeDartLine('a.b');
      expect(dotLine[1], const CodeToken('.', CodeTokenKind.punctuation));
      expect(dotLine.last, const CodeToken('b', CodeTokenKind.plain), reason: 'b is an identifier');
      final comma = tokenizeDartLine('a, b')[1];
      expect(comma.kind, CodeTokenKind.punctuation);
    });
  });

  group('AppCodeLines', () {
    testWidgets('maps token roles onto the --code-* brand colors', (tester) async {
      final light = generated.lightTheme;
      final brand = light.brand;
      await tester.pumpWidget(
        _harness(child: const AppCodeLines(source: "final n = 1; final s = 'hi';")),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final spans = <TextSpan>[];
      void walk(InlineSpan span) {
        if (span is TextSpan) {
          spans.add(span);
          span.children?.forEach(walk);
        }
      }

      walk(richText.text);

      Color colorOf(String text) {
        for (final textSpan in spans) {
          if (textSpan.text == text) {
            return textSpan.style!.color!;
          }
        }
        fail('no span for $text');
      }

      expect(colorOf('final'), light.colors.primary, reason: 'keyword takes the primary');
      expect(colorOf("'hi'"), brand.success, reason: 'strings take green');
      expect(colorOf('1'), brand.purple, reason: 'numbers take purple');
      expect(colorOf('n'), light.colors.foreground, reason: 'plain identifiers stay foreground');
    });

    testWidgets('keeps every line, including empty ones', (tester) async {
      await tester.pumpWidget(_harness(child: const AppCodeLines(source: 'a\n\nb')));
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect((richText.text as TextSpan).toPlainText(), 'a\n\nb');
    });
  });
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
