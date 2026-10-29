import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';

void main() {
  group('AppStatusTag', () {
    for (final brightness in Brightness.values) {
      final isDark = brightness == Brightness.dark;
      final fillOpacity = isDark ? 0.20 : 0.10;
      final theme = isDark ? generated.darkTheme : generated.lightTheme;
      final brand = AppBrandColors.forBrightness(brightness);

      for (final role in AppStatusRole.values) {
        testWidgets(
          'resolves $role to its soft role fill and role text at $brightness',
          (tester) async {
            await tester.pumpWidget(
              _harness(
                brightness: brightness,
                child: AppStatusTag(label: 'Active', role: role),
              ),
            );
            await tester.pump();

            final roleColor = brand.roleColor(role);
            final decoration = _tagDecoration(tester);
            expect(
              decoration.color,
              roleColor?.withValues(alpha: fillOpacity) ?? theme.colors.secondary,
            );
            expect(decoration.shape, isA<StadiumBorder>());
            expect(
              _tagTextColor(tester, 'Active'),
              roleColor ?? theme.colors.secondaryForeground,
            );
          },
        );
      }
    }

    testWidgets('soft status stays soft: brand fills never reach full opacity', (
      tester,
    ) async {
      for (final role in AppStatusRole.values) {
        await tester.pumpWidget(
          _harness(
            child: AppStatusTag(label: 'Active', role: role),
          ),
        );
        await tester.pump();
        if (role == AppStatusRole.neutral) {
          // Neutral status is deliberately plain grey, the absence of
          // meaning; only brand-colored roles must stay soft.
          continue;
        }
        expect(_tagDecoration(tester).color!.a, lessThan(1));
      }
    });

    testWidgets('showMarker draws the hollow ring marker in the role color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppStatusTag(
            label: 'Live',
            role: AppStatusRole.success,
            showMarker: true,
          ),
        ),
      );
      await tester.pump();

      final marker = tester.widget<AppRingMarker>(find.byType(AppRingMarker));
      expect(marker.filled, isFalse);
      expect(marker.size, 7);
      // The tag's own marker recipe is a 1.5px ring (size-1.75 border-[1.5px]).
      expect(marker.borderWidth, 1.5);
      expect(marker.color, AppBrandColors.light.success);
    });

    testWidgets('omits the marker by default', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppStatusTag(label: 'Active', role: AppStatusRole.info),
        ),
      );
      await tester.pump();

      expect(find.byType(AppRingMarker), findsNothing);
    });
  });
}

ShapeDecoration _tagDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(AppStatusTag),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is ShapeDecoration &&
                (widget.decoration! as ShapeDecoration).shape is StadiumBorder,
          ),
        )
        .first,
  );
  return container.decoration! as ShapeDecoration;
}

Color _tagTextColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

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
