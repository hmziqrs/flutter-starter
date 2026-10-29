import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/question.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

void main() {
  group('AppQuestion', () {
    testWidgets('sits closed with a hollow grey ring and a plus', (tester) async {
      await tester.pumpWidget(_harness(child: _question));
      final light = generated.lightTheme;

      final marker = tester.widget<AppRingMarker>(find.byType(AppRingMarker));
      expect(marker.filled, isFalse);
      expect(marker.color, light.colors.mutedForeground);
      expect(find.byIcon(FLucideIcons.plus), findsOneWidget);
      expect(find.text('One answer, in plain words.'), findsNothing);
    });

    testWidgets('fills the ring with primary and flips to a minus when open', (tester) async {
      final states = <bool>[];
      await tester.pumpWidget(
        _harness(
          child: AppQuestion(
            question: 'What does it cost?',
            answer: 'One answer, in plain words.',
            onChanged: states.add,
          ),
        ),
      );
      final light = generated.lightTheme;

      await tester.tap(find.text('What does it cost?'));
      await tester.pump();

      final marker = tester.widget<AppRingMarker>(find.byType(AppRingMarker));
      expect(marker.filled, isTrue, reason: 'Filled means open.');
      expect(marker.color, light.colors.primary);
      expect(find.byIcon(FLucideIcons.minus), findsOneWidget);
      expect(find.text('One answer, in plain words.'), findsOneWidget);
      expect(states, <bool>[true]);
    });

    testWidgets('toggles closed again, hollow ring restored', (tester) async {
      await tester.pumpWidget(_harness(child: _question));
      final light = generated.lightTheme;

      await tester.tap(find.text('What does it cost?'));
      await tester.pump();
      await tester.tap(find.text('What does it cost?'));
      await tester.pump();

      final marker = tester.widget<AppRingMarker>(find.byType(AppRingMarker));
      expect(marker.filled, isFalse);
      expect(marker.color, light.colors.mutedForeground);
      expect(find.text('One answer, in plain words.'), findsNothing);
    });

    testWidgets('answers start open when initiallyOpen is set', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppQuestion(
            question: 'What does it cost?',
            answer: 'One answer, in plain words.',
            initiallyOpen: true,
          ),
        ),
      );
      final light = generated.lightTheme;

      final marker = tester.widget<AppRingMarker>(find.byType(AppRingMarker));
      expect(marker.filled, isTrue);
      expect(marker.color, light.colors.primary);
      expect(find.text('One answer, in plain words.'), findsOneWidget);
    });
  });

  group('AppQuestions', _questionsTests);
}

void _questionsTests() {
  testWidgets('draws the opening line and one line under every row, never doubled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        child: const AppQuestions(questions: <AppQuestion>[_question, _question]),
      ),
    );
    final light = generated.lightTheme;

    final lines = tester
        .widgetList<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.constraints?.maxHeight == 1 &&
                widget.color == light.colors.border,
          ),
        )
        .toList();
    // questions.svelte's border-t plus each row's border-b: three lines.
    expect(lines, hasLength(3), reason: 'One line above, one under each row.');
  });

  testWidgets('renders the orange number instead of the ring', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: const AppQuestion(question: 'What does it cost?', answer: 'Nothing.', number: 1),
      ),
    );
    final light = generated.lightTheme;

    expect(find.byType(AppRingMarker), findsNothing);
    final number = tester.widget<Text>(find.text('01'));
    expect(number.style!.color, light.colors.primary);
  });

  testWidgets('shows the topic as a grey tag at the row end', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: const AppQuestion(question: 'How?', answer: 'Restart.', topic: 'Setup'),
      ),
    );
    final light = generated.lightTheme;

    final tag = tester.widget<Text>(find.text('Setup'));
    expect(tag.style!.color, light.colors.secondaryForeground);
    expect(find.byIcon(FLucideIcons.plus), findsOneWidget);
  });
}

const _question = AppQuestion(
  question: 'What does it cost?',
  answer: 'One answer, in plain words.',
);

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
