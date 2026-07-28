import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

/// Gives every routed page an opaque, theme-aware surface before applying its
/// platform transition.
///
/// Route widgets can focus on layout instead of each remembering to paint a
/// background. This also prevents the outgoing route from showing through
/// transparent areas of the incoming route during iOS swipe-back and desktop
/// cross-fades.
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

/// A page transition that cross-fades the incoming route over the outgoing one,
/// with no directional movement.
///
/// Used on desktop platforms (macOS, Windows, Linux) where a horizontal push
/// reads as mobile rather than native. The incoming page fades in over the
/// still-opaque outgoing page, so there is no see-through gap to whatever sits
/// behind it; popping reverses the dissolve.
///
/// Only the route's own [PageRoute.animation] drives the opacity: a covered
/// route keeps [PageRoute.secondaryAnimation] unused, so it stays opaque while
/// the new route fades in on top of it.
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

/// Page transition theme that matches each platform's native feel.
///
/// * iOS — the Cupertino horizontal slide (preserves the swipe-back gesture).
/// * Android & Fuchsia — the Material zoom.
/// * macOS, Windows, Linux — a cross-fade ([CrossFadePageTransitionsBuilder]),
///   mirroring how desktop apps swap content instead of pushing it.
///
/// Applied to the Material theme so go_router routes built with `builder:`
/// (which produce [MaterialPage]) inherit these transitions automatically via
/// [ThemeData.pageTransitionsTheme]. Each native delegate is wrapped in
/// [OpaquePageTransitionsBuilder], so every route also inherits a solid themed
/// page surface without feature-level background declarations.
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

/// Restrained, non-directional transitions for remote-first ten-foot UIs.
///
/// tvOS reports iOS through [defaultTargetPlatform], so selecting this theme
/// from application presentation policy prevents a television from inheriting
/// Cupertino edge-swipe transitions.
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
