import 'package:flutter/material.dart';

/// Local micro-interaction motion spec (independent from HMI/MotionDirector).
///
/// Scope:
/// - button/chip press feedback
/// - small opacity/scale highlight transitions
///
/// Non-scope:
/// - map/HUD/sheet spatial choreography
/// - global intent/state transitions
class MicroMotionSpec {
  MicroMotionSpec._();

  // 80ms - 180ms only.
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration medium = Duration(milliseconds: 140);
  static const Duration slow = Duration(milliseconds: 180);

  // Snappy, non-spring curves.
  static const Curve emphasisCurve = Curves.fastLinearToSlowEaseIn;
  static const Curve fadeCurve = Curves.easeOutCubic;

  static const double pressedScale = 0.96;
}

