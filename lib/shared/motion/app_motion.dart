import 'package:flutter/animation.dart';

/// Motion tokens for the app's openings and progress indicators.
///
/// Brand motion contract (BRAND.md s10, APP-BLOCKS "Shared rules"):
///
/// - Nothing moves on hover, press or focus. Feedback is color only: never
///   scale, translate or rotate a widget under a hover, press or focus
///   state. Cards tint their border, buttons tint their surface, links
///   underline.
/// - Things that open and close (dialogs, sheets, menus, popovers, toasts)
///   may fade and slide in using these durations and curves. Once on
///   screen they stay put.
/// - Indeterminate progress (spinners, shimmer skeletons) is the control
///   working, not drift; every pulse and spinner must stop under
///   reduced motion (`MediaQuery.disableAnimationsOf`).
/// - Ten-foot/TV focus scaling is the one exception: platform
///   accessibility idiom, driven by `AppPresentationTokens.focusScale`.
abstract final class AppMotion {
  /// Feedback and small control transitions (switches, chips, hover tints).
  static const quick = Duration(milliseconds: 140);

  /// Standard openings: menus, popovers, toasts.
  static const standard = Duration(milliseconds: 220);

  /// Deliberate openings: dialogs, sheets, and one shimmer sweep.
  static const deliberate = Duration(milliseconds: 360);

  /// How long a TV remote chord must be held before it registers.
  static const keyboardChordHold = Duration(milliseconds: 700);

  /// Entry curve for openings; decelerates into place and stops.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Emphasized curve for large surfaces (dialogs, sheets).
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
}
