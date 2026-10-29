import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/person_card.dart';

void main() {
  group('AppPersonCard', () {
    testWidgets('stacks avatar, name pair, bio and links like the kit card', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(
            width: 320,
            child: AppPersonCard(
              name: 'Priya Nair',
              role: 'Operations',
              bio: 'Runs the Friday check-in.',
              links: <String>['@priya'],
            ),
          ),
        ),
      );

      final order = <double>[
        tester.getTopLeft(find.text('PN')).dy,
        tester.getTopLeft(find.text('Priya Nair')).dy,
        tester.getTopLeft(find.text('Operations')).dy,
        tester.getTopLeft(find.text('Runs the Friday check-in.')).dy,
        tester.getTopLeft(find.text('@priya')).dy,
      ];
      for (var i = 0; i < order.length - 1; i++) {
        expect(order[i], lessThan(order[i + 1]), reason: 'block $i must sit above block ${i + 1}');
      }
    });

    testWidgets('draws the avatar as a 56dp hollow ring with muted initials', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(width: 320, child: AppPersonCard(name: 'Priya Nair')),
        ),
      );

      final circleFinder = find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        return decoration is ShapeDecoration &&
            decoration.shape is RoundedSuperellipseBorder &&
            (decoration.shape as RoundedSuperellipseBorder).side.color ==
                generated.lightTheme.colors.foreground.withValues(alpha: 0.15);
      });
      final avatar = tester.widget<DecoratedBox>(circleFinder.first).decoration as ShapeDecoration;
      final ring = avatar.shape as RoundedSuperellipseBorder;
      // Avatar.Fallback ring-foreground/15, bg-transparent.
      expect(ring.side.color, generated.lightTheme.colors.foreground.withValues(alpha: 0.15));
      expect(avatar.color, Colors.transparent);
      expect(tester.getSize(circleFinder.first).width, 56);

      final initials = tester.widget<Text>(find.text('PN')).style!;
      expect(initials.color, generated.lightTheme.colors.mutedForeground);
      expect(initials.fontWeight, FontWeight.w500);
    });

    testWidgets('keeps the name in the text color at w500 and the role muted', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(
            width: 320,
            child: AppPersonCard(name: 'Priya Nair', role: 'Ops'),
          ),
        ),
      );

      final name = tester.widget<Text>(find.text('Priya Nair')).style!;
      expect(name.color, generated.lightTheme.colors.foreground);
      expect(name.fontWeight, FontWeight.w500);

      final role = tester.widget<Text>(find.text('Ops')).style!;
      expect(role.color, generated.lightTheme.colors.mutedForeground);
    });

    testWidgets('renders the card ring as the foreground at 10%', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(width: 320, child: AppPersonCard(name: 'Priya Nair')),
        ),
      );

      final card =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(AppPersonCard),
                          matching: find.byWidgetPredicate(
                            (widget) =>
                                widget is DecoratedBox &&
                                widget.decoration is ShapeDecoration &&
                                (widget.decoration as ShapeDecoration).shape
                                    is RoundedSuperellipseBorder,
                          ),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;
      expect(
        (card.shape as RoundedSuperellipseBorder).side.color,
        generated.lightTheme.colors.foreground.withValues(alpha: 0.10),
      );
    });
  });
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
