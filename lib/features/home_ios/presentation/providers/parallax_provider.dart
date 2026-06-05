import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Offset parallax wallpaper từ cảm biến thiết bị.
class ParallaxNotifier extends Notifier<Offset> {
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  Offset build() {
    ref.onDispose(() => _sub?.cancel());
    if (_supportsAccelerometer) {
      _sub = accelerometerEventStream().listen(_onAccel);
    }
    return Offset.zero;
  }

  static bool get _supportsAccelerometer {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  void _onAccel(AccelerometerEvent event) {
    final dx = (event.x.clamp(-8.0, 8.0) / 8.0) * 12;
    final dy = (event.y.clamp(-8.0, 8.0) / 8.0) * 12;
    final next = Offset(dx, dy);
    if ((next - state).distance > 0.4) state = next;
  }
}

final parallaxProvider =
    NotifierProvider<ParallaxNotifier, Offset>(ParallaxNotifier.new);
