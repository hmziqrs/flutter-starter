import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

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
/// [ThemeData.pageTransitionsTheme].
const nativePageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    TargetPlatform.macOS: CrossFadePageTransitionsBuilder(),
    TargetPlatform.windows: CrossFadePageTransitionsBuilder(),
    TargetPlatform.linux: CrossFadePageTransitionsBuilder(),
  },
);
