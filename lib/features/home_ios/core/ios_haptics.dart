import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Haptic feedback — chỉ trên thiết bị di động.
class IosHaptics {
  IosHaptics._();

  static bool get enabled =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> appOpen() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> appClose() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }
}
