import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/motion/app_page_transitions.dart';

void main() {
  group('nativePageTransitionsTheme', () {
    test('maps each platform to its native builder', () {
      expect(
        _delegateFor(TargetPlatform.iOS),
        isA<CupertinoPageTransitionsBuilder>(),
      );
      expect(
        _delegateFor(TargetPlatform.android),
        isA<ZoomPageTransitionsBuilder>(),
      );
      expect(
        _delegateFor(TargetPlatform.fuchsia),
        isA<ZoomPageTransitionsBuilder>(),
      );
      expect(
        _delegateFor(TargetPlatform.macOS),
        isA<CrossFadePageTransitionsBuilder>(),
      );
      expect(
        _delegateFor(TargetPlatform.windows),
        isA<CrossFadePageTransitionsBuilder>(),
      );
      expect(
        _delegateFor(TargetPlatform.linux),
        isA<CrossFadePageTransitionsBuilder>(),
      );
    });

    test('wraps every platform delegate in the shared opaque page surface', () {
      expect(
        nativePageTransitionsTheme.builders.values,
        everyElement(isA<OpaquePageTransitionsBuilder>()),
      );
    });
  });

  testWidgets('OpaquePageTransitionsBuilder paints the themed page background', (
    tester,
  ) async {
    const pageColor = Color(0xFF123456);
    const builder = OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    );
    const animation = AlwaysStoppedAnimation<double>(1);
    const secondary = AlwaysStoppedAnimation<double>(0);
    final route = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: pageColor),
        home: Builder(
          builder: (context) {
            return builder.buildTransitions<void>(
              route,
              context,
              animation,
              secondary,
              const SizedBox.expand(key: ValueKey('transparent-route-content')),
            );
          },
        ),
      ),
    );

    final surface = tester
        .element(find.byKey(const ValueKey('transparent-route-content')))
        .findAncestorWidgetOfExactType<ColoredBox>()!;
    expect(surface.color, pageColor);
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

PageTransitionsBuilder _delegateFor(TargetPlatform platform) {
  final builder = nativePageTransitionsTheme.builders[platform]! as OpaquePageTransitionsBuilder;
  return builder.delegate;
}
