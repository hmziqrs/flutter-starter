import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class OpaquePageTransitionsBuilder extends PageTransitionsBuilder {
  const OpaquePageTransitionsBuilder({required this.delegate});

  final PageTransitionsBuilder delegate;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return delegate.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }
}

class CrossFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const CrossFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

const nativePageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.iOS: OpaquePageTransitionsBuilder(
      delegate: CupertinoPageTransitionsBuilder(),
    ),
    TargetPlatform.android: OpaquePageTransitionsBuilder(
      delegate: ZoomPageTransitionsBuilder(),
    ),
    TargetPlatform.fuchsia: OpaquePageTransitionsBuilder(
      delegate: ZoomPageTransitionsBuilder(),
    ),
    TargetPlatform.macOS: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
    TargetPlatform.windows: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
    TargetPlatform.linux: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
  },
);

/// tvOS reports as iOS to defaultTargetPlatform; override keeps TV off Cupertino swipe transitions.
const televisionPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.iOS: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
    TargetPlatform.android: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
    TargetPlatform.fuchsia: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
    TargetPlatform.macOS: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
    TargetPlatform.windows: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
    TargetPlatform.linux: OpaquePageTransitionsBuilder(
      delegate: CrossFadePageTransitionsBuilder(),
    ),
  },
);
