import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const deliberate = Duration(milliseconds: 360);
  static const keyboardChordHold = Duration(milliseconds: 700);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
}
