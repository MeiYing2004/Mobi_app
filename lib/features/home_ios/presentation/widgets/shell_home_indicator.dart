import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_indicator_controller.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';

/// Home Indicator — pill trắng mờ, kích thước responsive theo iPhone.
class ShellHomeIndicator extends ConsumerStatefulWidget {
  const ShellHomeIndicator({
    super.key,
    required this.screenWidth,
    required this.bottomPadding,
    this.pillWidth,
    this.pillHeight,
  });

  final double screenWidth;
  final double bottomPadding;
  final double? pillWidth;
  final double? pillHeight;

  static const double hitHeight = 48;

  @override
  ConsumerState<ShellHomeIndicator> createState() => _ShellHomeIndicatorState();
}

class _ShellHomeIndicatorState extends ConsumerState<ShellHomeIndicator> {
  double _activeDrag = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy >= 0) return;
    final controller = ref.read(homeIndicatorDragProvider.notifier);
    final next = (_activeDrag - details.delta.dy).clamp(0.0, 240.0);
    if ((next - _activeDrag).abs() < 0.5) return;
    setState(() => _activeDrag = next);
    controller.updateDrag(next);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final controller = ref.read(homeIndicatorDragProvider.notifier);
    await controller.endDrag(
      _activeDrag,
      velocity: details.primaryVelocity ?? 0,
    );
    if (mounted) setState(() => _activeDrag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isAppOpen = ref.watch(isAppOpenProvider);
    final visualDrag =
        isAppOpen ? ref.watch(homeIndicatorDragProvider) : 0.0;
    final pillW = widget.pillWidth ?? widget.screenWidth * 0.36;
    final pillH = widget.pillHeight ?? 5.0;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: SizedBox(
        width: widget.screenWidth,
        height: ShellHomeIndicator.hitHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: isAppOpen
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  onVerticalDragCancel: () {
                    ref.read(homeIndicatorDragProvider.notifier).resetDrag();
                    setState(() => _activeDrag = 0);
                  },
                  child: _IndicatorPill(
                    dragOffset: visualDrag,
                    width: pillW,
                    height: pillH,
                  ),
                )
              : IgnorePointer(
                  child: _IndicatorPill(
                    dragOffset: 0,
                    width: pillW,
                    height: pillH,
                  ),
                ),
        ),
      ),
    );
  }
}

class _IndicatorPill extends StatelessWidget {
  const _IndicatorPill({
    required this.dragOffset,
    required this.width,
    required this.height,
  });

  final double dragOffset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -dragOffset * 0.05),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.12),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
