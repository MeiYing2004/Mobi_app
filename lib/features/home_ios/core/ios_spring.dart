import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Spring animation kiểu UIKit — ~300ms, damping ratio ~0.86.
abstract final class IosSpring {
  static const Duration nominalDuration = Duration(milliseconds: 300);

  /// Mở app — phản hồi nhanh, ít overshoot.
  static const SpringDescription openApp = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 33,
  );

  /// Đóng app — hơi stiff hơn để snap về icon.
  static const SpringDescription closeApp = SpringDescription(
    mass: 1,
    stiffness: 460,
    damping: 35,
  );

  /// Nhấn icon — spring về 1.0 khi thả.
  static const SpringDescription pressRelease = SpringDescription(
    mass: 1,
    stiffness: 650,
    damping: 38,
  );

  /// Dynamic Island / UI chrome.
  static const SpringDescription island = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 31,
  );

  /// Snappy — page dots, drag highlight.
  static const SpringDescription snappy = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 36,
  );

  static Future<void> animate(
    AnimationController controller, {
    required double target,
    SpringDescription spring = openApp,
    double velocity = 0,
  }) {
    return controller.animateWith(
      SpringSimulation(
        spring,
        controller.value,
        target,
        velocity,
      ),
    );
  }
}
