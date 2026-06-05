import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';

/// Ngưỡng vuốt lên từ Home Indicator để về Home (px).
const kHomeIndicatorDismissThreshold = 80.0;

/// Điều khiển gesture Home Indicator — nơi duy nhất được phép đóng app.
class HomeIndicatorController extends Notifier<double> {
  Future<void> Function()? _dismissHandler;

  @override
  double build() => 0;

  void registerDismissHandler(Future<void> Function() handler) {
    _dismissHandler = handler;
  }

  void updateDrag(double offset) {
    state = offset.clamp(0.0, 240.0);
  }

  void resetDrag() {
    state = 0;
  }

  /// Chỉ vuốt lên từ Home Indicator (dy < 0), không tap, không vuốt nền.
  Future<void> endDrag(double offset, {required double velocity}) async {
    final swipedUp = velocity < -400;
    final shouldDismiss =
        offset >= kHomeIndicatorDismissThreshold || swipedUp;
    if (shouldDismiss) {
      await _dismissHandler?.call();
    }
    state = 0;
  }
}

final homeIndicatorDragProvider =
    NotifierProvider<HomeIndicatorController, double>(
  HomeIndicatorController.new,
);

/// Re-export tiện cho Shell.
final isFuelTrackerOpenProvider = isAppOpenProvider;
