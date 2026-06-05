import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_haptics.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/system_overlay_provider.dart';

/// Nhận cử chỉ hệ thống iOS — Spotlight, Control Center, Notification Center.
class IosGestureLayer extends ConsumerWidget {
  const IosGestureLayer({
    super.key,
    required this.metrics,
    required this.enabled,
    required this.child,
  });

  final IosHomeMetrics metrics;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    final topZone = metrics.topPadding + metrics.statusBarHeight + 80;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topZone,
          child: Row(
            children: [
              Expanded(
                child: _EdgeSwipeZone(
                  onSwipeDown: () {
                    IosHaptics.light();
                    ref
                        .read(systemOverlayProvider.notifier)
                        .show(IosSystemOverlay.notificationCenter);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: _EdgeSwipeZone(
                  onSwipeDown: () {
                    IosHaptics.light();
                    ref
                        .read(systemOverlayProvider.notifier)
                        .show(IosSystemOverlay.spotlight);
                  },
                ),
              ),
              Expanded(
                child: _EdgeSwipeZone(
                  onSwipeDown: () {
                    IosHaptics.light();
                    ref
                        .read(systemOverlayProvider.notifier)
                        .show(IosSystemOverlay.controlCenter);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EdgeSwipeZone extends StatelessWidget {
  const _EdgeSwipeZone({required this.onSwipeDown});

  final VoidCallback onSwipeDown;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 280) onSwipeDown();
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 18) onSwipeDown();
      },
    );
  }
}
