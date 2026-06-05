import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

import 'package:fuel_tracker_app/core/hmi_intents.dart';

/// Unified cinematic motion timeline for map/HUD/sheet choreography.
///
/// Timeline stages (sheet opening):
/// 1) Map dim   [0.00..0.35]
/// 2) HUD retreat [0.18..0.72]
/// 3) Sheet rise  [0.34..1.00]
class MotionDirector extends ChangeNotifier {
  MotionDirector({required TickerProvider vsync}) {
    _master = AnimationController(
      vsync: vsync,
      lowerBound: 0,
      upperBound: 1,
      value: 0,
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 420),
    )..addListener(notifyListeners);
  }

  late final AnimationController _master;
  double _sheetDrag = 0.0;

  double get timeline => _master.value;

  /// Map dim/haze layer (primary stage 1).
  double get mapDim => _interval(
        timeline,
        begin: 0.0,
        end: 0.35,
        curve: Curves.easeOutCubic,
      );

  /// HUD retreat from focus (stage 2).
  double get hudRetreat => _interval(
        timeline,
        begin: 0.18,
        end: 0.72,
        curve: Curves.fastLinearToSlowEaseIn,
      );

  /// Sheet rise + material lift (stage 3), merged with drag progress.
  double get sheetRise {
    final staged = _interval(
      timeline,
      begin: 0.34,
      end: 1.0,
      curve: Curves.easeOutCubic,
    );
    return (staged * 0.78 + _sheetDrag * 0.22).clamp(0.0, 1.0);
  }

  /// Executes choreography only; no interaction decision logic.
  void applyIntent({
    required HmiIntent intent,
    required HmiSpatialState spatialState,
  }) {
    // Spatial state is intentionally passed in for choreography context
    // and future expansion (depth-aware timelines).
    final _ = spatialState;
    switch (intent.type) {
      case HmiIntentType.openSheet:
        _animateTo(1, const SpringDescription(mass: 1, stiffness: 620, damping: 42));
        return;
      case HmiIntentType.expandSheet:
        _sheetDrag = intent.value.clamp(0, 1);
        notifyListeners();
        return;
      case HmiIntentType.collapseSheet:
      case HmiIntentType.focusMap:
      case HmiIntentType.deactivateNavigation:
        _sheetDrag = 0;
        _animateTo(0, const SpringDescription(mass: 1, stiffness: 560, damping: 40));
        return;
      case HmiIntentType.activateNavigation:
        // Keep map focus clear when entering navigation mode.
        _sheetDrag = 0;
        _animateTo(0, const SpringDescription(mass: 1, stiffness: 560, damping: 40));
        return;
    }
  }

  void _animateTo(double target, SpringDescription spring) {
    final sim = SpringSimulation(
      spring,
      _master.value,
      target,
      0,
    );
    _master.animateWith(sim);
  }

  double _interval(
    double t, {
    required double begin,
    required double end,
    required Curve curve,
  }) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    final n = (t - begin) / (end - begin);
    return curve.transform(n.clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }
}

