import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/ios_design_tokens.dart';
import '../core/micro_motion_spec.dart';
import '../core/motion_director.dart';
import '../core/vehicle_ui_tokens.dart';
import '../models/navigation_route.dart';

/// Cinematic Navigation HUD — quiet hierarchy, spatial depth above map.
class NavigationHud extends StatelessWidget {
  final NavigationRoute route;
  final VoidCallback onClose;
  final VoidCallback? onSwitchCloserStation;
  final MotionDirector? motionDirector;

  const NavigationHud({
    super.key,
    required this.route,
    required this.onClose,
    this.onSwitchCloserStation,
    this.motionDirector,
  });

  @override
  Widget build(BuildContext context) {
    final fuel = route.fuelAnalysis;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final b = Theme.of(context).brightness;

    Widget content(double f) {
      final opacity = (1.0 - f * 0.55).clamp(0.0, 1.0);
      final lift = 8.0 * f;

      return Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, lift),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, bottom + 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: VehicleUi.cardFor(b).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 26,
                        spreadRadius: -14,
                        offset: const Offset(0, 18),
                      ),
                      BoxShadow(
                        color: VehicleUi.accentBlueGlow.withValues(alpha: 0.26),
                        blurRadius: 56,
                        spreadRadius: -40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Ambient edge light (very restrained).
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
                            border: Border.all(
                              color: VehicleUi.accentBlue.withValues(alpha: 0.10),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _HudIconButton(
                                  onTap: onClose,
                                  icon: Icons.close_rounded,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Đi đến',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.1,
                                          color: VehicleUi.textMuted.withValues(alpha: 0.92),
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        route.destination.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          letterSpacing: -0.5,
                                          color: Colors.white,
                                          height: 1.05,
                                        ),
                                      ),
                                      if (route.destination.brand.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          route.destination.brand,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: VehicleUi.textMuted.withValues(alpha: 0.92),
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _PrimaryMetric(
                                  label: 'ETA',
                                  value: route.etaLabel,
                                  accent: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _PrimaryMetric(
                                    label: 'Khoảng cách',
                                    value: route.distanceLabel,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PrimaryMetric(
                                    label: 'Thời gian',
                                    value: route.durationLabel,
                                  ),
                                ),
                              ],
                            ),
                            if (fuel.insufficientFuel) ...[
                              const SizedBox(height: 12),
                              _WarningStrip(
                                title: 'Nhiên liệu không đủ',
                                subtitle: fuel.suggestedCloserStation != null
                                    ? 'Gợi ý: ${fuel.suggestedCloserStation!.name}'
                                    : 'Hãy chọn trạm gần hơn',
                                onAction: onSwitchCloserStation,
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'OSRM • OpenStreetMap',
                              style: TextStyle(
                                fontSize: 10,
                                color: VehicleUi.textMuted.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (motionDirector == null) {
      return content(0);
    }

    return AnimatedBuilder(
      animation: motionDirector!,
      builder: (context, _) => content(motionDirector!.hudRetreat),
    );
  }
}

class _HudIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _HudIconButton({required this.onTap, required this.icon});

  @override
  State<_HudIconButton> createState() => _HudIconButtonState();
}

class _HudIconButtonState extends State<_HudIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? MicroMotionSpec.pressedScale : 1.0,
        duration: MicroMotionSpec.fast,
        curve: MicroMotionSpec.emphasisCurve,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(widget.icon, size: 18, color: Colors.white.withValues(alpha: 0.92)),
        ),
      ),
    );
  }
}

class _PrimaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _PrimaryMetric({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ? VehicleUi.accentBlue : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: VehicleUi.textMuted.withValues(alpha: 0.9),
            height: 1.1,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.05,
            color: c.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _WarningStrip extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAction;

  const _WarningStrip({
    required this.title,
    required this.subtitle,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IosDesign.warningRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: IosDesign.warningRed.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: IosDesign.warningRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: IosDesign.warningRed,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: IosDesign.warningRed,
                side: BorderSide(color: IosDesign.warningRed.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Đổi trạm'),
            ),
          ],
        ],
      ),
    );
  }
}
