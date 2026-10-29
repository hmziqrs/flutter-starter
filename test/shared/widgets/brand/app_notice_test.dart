import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_notice.dart';

void main() {
  group('AppNotice', () {
    const icons = <AppStatusRole, IconData>{
      AppStatusRole.info: FLucideIcons.info,
      AppStatusRole.neutral: FLucideIcons.info,
      AppStatusRole.success: FLucideIcons.circleCheck,
      AppStatusRole.warning: FLucideIcons.triangleAlert,
      AppStatusRole.destructive: FLucideIcons.octagonAlert,
    };

    for (final MapEntry(key: role, value: icon) in icons.entries) {
      testWidgets('$role carries its role color on a thin line and its icon', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(
            child: AppNotice(title: 'Heads up', body: 'Details follow.', role: role),
          ),
        );
        await tester.pump();

        final roleColor =
            AppBrandColors.light.roleColor(role) ?? generated.lightTheme.colors.mutedForeground;
        final decoration = _noticeDecoration(tester);
        expect(decoration.color, Colors.transparent);
        expect(
          (decoration.shape as RoundedSuperellipseBorder).side.color,
          roleColor.withValues(alpha: 0.4),
        );
        final noticeIcon = tester.widget<Icon>(find.byType(Icon));
        expect(noticeIcon.icon, icon);
        expect(noticeIcon.color, roleColor);
      });
    }

    testWidgets('keeps title and body in the normal text colors', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppNotice(
            title: 'We send a link to the new address',
            body: 'The change happens when you open it.',
          ),
        ),
      );
      await tester.pump();

      final colors = generated.lightTheme.colors;
      final titleStyle = tester.widget<Text>(find.text('We send a link to the new address')).style!;
      expect(titleStyle.color, colors.foreground);
      expect(titleStyle.fontWeight, FontWeight.w500);
      expect(
        tester.widget<Text>(find.text('The change happens when you open it.')).style!.color,
        colors.mutedForeground,
      );
    });

    testWidgets('uses the brand alert metrics: 16/12 padding and a 10px icon gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppNotice(title: 'Heads up', body: 'Details follow.'),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(AppNotice), matching: find.byType(Container)).first,
      );
      expect(container.padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 12));
      final gaps = tester.widgetList<SizedBox>(
        find.descendant(of: find.byType(AppNotice), matching: find.byType(SizedBox)),
      );
      expect(gaps.map((box) => box.width), contains(10));
    });

    testWidgets('omits the body line when none is given', (tester) async {
      await tester.pumpWidget(_harness(child: const AppNotice(title: 'Heads up')));
      await tester.pump();

      expect(find.text('Heads up'), findsOneWidget);
      expect(tester.widgetList<Text>(find.byType(Text)), hasLength(1));
    });
  });
}

ShapeDecoration _noticeDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(AppNotice), matching: find.byType(Container)).first,
  );
  return container.decoration! as ShapeDecoration;
}

Widget _harness({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
