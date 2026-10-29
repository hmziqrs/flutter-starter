import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/copy_button.dart';

void main() {
  group('AppCopyButton', () {
    testWidgets('copies its text and flips the icon to a green check', (tester) async {
      final light = generated.lightTheme;
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments! as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      await tester.pumpWidget(
        _harness(
          child: const AppCopyButton(text: 'flutter test', label: 'Copy'),
        ),
      );
      expect(find.byIcon(FLucideIcons.copy), findsOneWidget);

      await tester.tap(find.byType(AppCopyButton));
      await tester.pump();

      expect(clipboard, 'flutter test');

      final check = tester.widget<Icon>(find.byIcon(FLucideIcons.check));
      expect(check.color, light.brand.success);

      // Runs out the revert timer so the test ends with none pending.
      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    });

    testWidgets('announces itself with the caller\u2019s labels', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppCopyButton(text: 'x', label: 'Copy', copiedLabel: 'Copied'),
        ),
      );
      expect(
        tester.widget<Icon>(find.byIcon(FLucideIcons.copy)).semanticLabel,
        'Copy',
      );

      await tester.tap(find.byType(AppCopyButton));
      await tester.pump();
      expect(
        tester.widget<Icon>(find.byIcon(FLucideIcons.check)).semanticLabel,
        'Copied',
      );

      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    });

    testWidgets('flips back to Copy after two seconds', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppCopyButton(text: 'x', label: 'Copy'),
        ),
      );
      await tester.tap(find.byType(AppCopyButton));
      await tester.pump();
      expect(find.byIcon(FLucideIcons.check), findsOneWidget);

      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
      expect(find.byIcon(FLucideIcons.check), findsNothing);
      expect(find.byIcon(FLucideIcons.copy), findsOneWidget);
    });

    testWidgets('says Copied while copied, even without a copied label', (tester) async {
      // The svelte button always shows "Copied" while the check is up
      // (copy-button.svelte: `{copied ? "Copied" : label}`), whatever the
      // rest label says.
      await tester.pumpWidget(
        _harness(
          child: const AppCopyButton(
            text: 'x',
            label: 'Copy the command',
            style: AppCopyButtonStyle.outline,
          ),
        ),
      );
      expect(find.text('Copy the command'), findsOneWidget);

      await tester.tap(find.byType(AppCopyButton));
      await tester.pump();
      expect(find.text('Copied'), findsOneWidget);
      expect(find.text('Copy the command'), findsNothing);

      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
      expect(find.text('Copy the command'), findsOneWidget);
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
