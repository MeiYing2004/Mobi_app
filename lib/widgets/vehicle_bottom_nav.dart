import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../core/micro_motion_spec.dart';
import '../core/vehicle_ui_tokens.dart';

class VehicleNavItem {
  final IconData icon;
  final String label;

  const VehicleNavItem({required this.icon, required this.label});
}

/// Next-generation floating dock — springy active indicator + pressed depth.
class VehicleBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<VehicleNavItem> items;

  const VehicleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const double barHeight = 52;

  @override
  State<VehicleBottomNav> createState() => _VehicleBottomNavState();
}

class _VehicleBottomNavState extends State<VehicleBottomNav>
    with TickerProviderStateMixin {
  late final AnimationController _indicator;
  late final AnimationController _breath;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    final upper = math.max(0, widget.items.length - 1).toDouble();

    _indicator = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: upper,
      value: widget.currentIndex.toDouble().clamp(0.0, upper),
    );

    // Subtle "breathing" lift for the dock feel.
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant VehicleBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    _springTo(widget.currentIndex);
  }

  void _springTo(int toIndex) {
    final to = toIndex.toDouble();
    final from = _indicator.value;
    final upper = _indicator.upperBound;
    final clampedTo = to.clamp(0.0, upper);

    if ((from - clampedTo).abs() < 0.001) return;

    final simulation = SpringSimulation(
      SpringDescription(mass: 1, stiffness: 700, damping: 38),
      from,
      clampedTo,
      0,
    );
    _indicator.animateWith(simulation);
  }

  @override
  void dispose() {
    _indicator.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isLight = b == Brightness.light;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = widget.items.length;
                final itemW = constraints.maxWidth / math.max(1, count);
                final bubbleW = 46.0;
                final bubbleH = VehicleBottomNav.barHeight - 14;
                final bubbleTop = 6.0;
                final bubbleRadius = VehicleUi.radiusMd;

                final floatT = _breath.value;
                final floatDy = (1.0 - 2.0 * floatT) * 1.2;

                return Container(
                  height: VehicleBottomNav.barHeight,
                  decoration: BoxDecoration(
                    color: VehicleUi.cardFor(b).withValues(alpha: isLight ? 0.9 : 0.92),
                    borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
                    border: Border.all(color: VehicleUi.glassBorderFor(b)),
                    boxShadow: VehicleUi.floatingShadowFarFor(b),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _indicator,
                        builder: (context, _) {
                          final selectedX =
                              _indicator.value * itemW + (itemW - bubbleW) / 2;
                          return Positioned(
                            left: selectedX,
                            top: bubbleTop + floatDy,
                            child: IgnorePointer(
                              child: Container(
                                width: bubbleW,
                                height: bubbleH,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(bubbleRadius),
                                  color: VehicleUi.accentBlue.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: VehicleUi.accentBlueGlow,
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: VehicleUi.accentBlueGlow.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      spreadRadius: -6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Row(
                        children: List.generate(count, (i) {
                          final item = widget.items[i];
                          final selected = i == widget.currentIndex;
                          final pressed = _pressedIndex == i;

                          return Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTapDown: (_) => setState(() => _pressedIndex = i),
                                onTapCancel: () => setState(() => _pressedIndex = null),
                                onTap: () {
                                  setState(() => _pressedIndex = null);
                                  widget.onTap(i);
                                },
                                borderRadius: BorderRadius.circular(VehicleUi.radiusMd),
                                splashColor: VehicleUi.accentBlue.withValues(
                                  alpha: isLight ? 0.14 : 0.18,
                                ),
                                highlightColor: VehicleUi.accentBlue.withValues(
                                  alpha: isLight ? 0.08 : 0.10,
                                ),
                                child: AnimatedScale(
                                  scale: pressed ? MicroMotionSpec.pressedScale : 1.0,
                                  duration: MicroMotionSpec.fast,
                                  curve: MicroMotionSpec.emphasisCurve,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 5,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 20,
                                          color: selected
                                              ? VehicleUi.accentBlue
                                              : VehicleUi.textMutedFor(b),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9,
                                            height: 1,
                                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                            color: selected ? VehicleUi.textPrimary : VehicleUi.textMutedFor(b),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
