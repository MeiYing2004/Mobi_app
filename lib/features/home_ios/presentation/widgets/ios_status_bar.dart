import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_typography.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/dynamic_island.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_status_icons.dart';

/// Chế độ đồng hồ status bar.
enum IosStatusBarMode {
  /// Thời gian cố định — chỉ lấy lúc build, không Timer.
  static,

  /// Cập nhật định kỳ bằng [Timer.periodic].
  live,
}

/// Status bar iOS 18 — giờ trái, island giữa, sóng/wifi/pin phải.
class IosStatusBar extends StatefulWidget {
  const IosStatusBar({
    super.key,
    required this.metrics,
    this.mode = IosStatusBarMode.live,
    this.isLight = false,
    this.showIsland = true,
  });

  final IosHomeMetrics metrics;
  final IosStatusBarMode mode;
  final bool isLight;
  final bool showIsland;

  @override
  State<IosStatusBar> createState() => _IosStatusBarState();
}

class _IosStatusBarState extends State<IosStatusBar> {
  Timer? _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startClockIfNeeded();
  }

  @override
  void didUpdateWidget(covariant IosStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _clockTimer?.cancel();
      _clockTimer = null;
      _now = DateTime.now();
      _startClockIfNeeded();
    }
  }

  void _startClockIfNeeded() {
    if (widget.mode != IosStatusBarMode.live) return;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) =>
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

  Color get _foreground =>
      widget.isLight ? const Color(0xFF0B1220) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final timeLabel = widget.mode == IosStatusBarMode.live
        ? _formatTime(_now)
        : _formatTime(DateTime.now());
    final fontSize = 17.0 * metrics.scale;
    final sideInset = metrics.statusBarSideInset;
    final contentTop = metrics.statusBarContentTop;
    final fg = _foreground;

    return SizedBox(
      height: metrics.statusBarTotalHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: sideInset,
            top: contentTop,
            child: Text(
              timeLabel,
              style: IosTypography.statusTime(fontSize).copyWith(color: fg),
            ),
          ),
          Positioned(
            right: sideInset,
            top: contentTop + fontSize * 0.06,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IosStatusIcons.signalBars(height: fontSize * 0.68, color: fg),
                SizedBox(width: fontSize * 0.3),
                IosStatusIcons.wifi(size: fontSize * 0.78, color: fg),
                SizedBox(width: fontSize * 0.3),
                IosStatusIcons.battery(height: fontSize * 0.68, color: fg),
              ],
            ),
          ),
          if (widget.showIsland)
            Positioned(
              top: metrics.islandTopOffset,
              child: DynamicIsland(metrics: metrics, compact: true),
            ),
        ],
      ),
    );
  }
}
