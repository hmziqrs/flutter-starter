import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/motion/app_page_transitions.dart';

void main() {
  group('nativePageTransitionsTheme', () {
    test('maps each platform to its native builder', () {
      expect(
        nativePageTransitionsTheme.builders[TargetPlatform.iOS],
        isA<CupertinoPageTransitionsBuilder>(),
      );
      expect(
        nativePageTransitionsTheme.builders[TargetPlatform.android],
        isA<ZoomPageTransitionsBuilder>(),
      );
      expect(
        nativePageTransitionsTheme.builders[TargetPlatform.fuchsia],
        isA<ZoomPageTransitionsBuilder>(),
      );
      expect(
        nativePageTransitionsTheme.builders[TargetPlatform.macOS],
        isA<CrossFadePageTransitionsBuilder>(),
      );
      expect(
        nativePageTransitionsTheme.builders[TargetPlatform.windows],
        isA<CrossFadePageTransitionsBuilder>(),
      );
      expect(
        nativePageTransitionsTheme.builders[TargetPlatform.linux],
        isA<CrossFadePageTransitionsBuilder>(),
      );
    });
  });

  testWidgets('CrossFadePageTransitionsBuilder wraps the page in a fade, never a slide', (
    tester,
  ) async {
    const builder = CrossFadePageTransitionsBuilder();
    const animation = AlwaysStoppedAnimation<double>(0.5);
    const secondary = AlwaysStoppedAnimation<double>(0);

    // Invoke buildTransitions inside a real widget tree so it receives a live
    // BuildContext, then assert what it emits — without a Navigator or any
    // platform resolution.
    Widget? built;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            built = builder.buildTransitions<void>(
              null,
              context,
              animation,
              secondary,
              const SizedBox.shrink(),
            );
            return built!;
          },
        ),
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    expect(
      find.byType(SlideTransition),
      findsNothing,
      reason: 'cross-fade must not translate the page',
    );
    expect(
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value,
      0.5,
      reason: 'the incoming page opacity must track the route animation',
    );
  });
}
