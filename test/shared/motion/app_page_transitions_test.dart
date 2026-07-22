import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
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

  testWidgets('desktop routes cross-fade without sliding', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(pageTransitionsTheme: nativePageTransitionsTheme),
        home: const ColoredBox(
          color: Color(0xffff0000),
          child: SizedBox.expand(),
        ),
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const ColoredBox(
            color: Color(0xff00ff00),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    // Begin the push, then advance to the middle of the 300ms transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // No SlideTransition drives the incoming page — that would be the old
    // macOS/iOS horizontal push the cross-fade replaces.
    expect(
      find.byType(SlideTransition),
      findsNothing,
      reason: 'desktop cross-fade must not translate the page',
    );

    // The incoming route is mid cross-fade: its opacity is strictly between
    // fully transparent and fully opaque.
    final animating = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .where((fade) => fade.opacity.value > 0 && fade.opacity.value < 1);
    expect(
      animating,
      isNotEmpty,
      reason: 'incoming route should be fading in',
    );
  });
}
