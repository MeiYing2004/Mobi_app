import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/core/theme/luxury_widgets.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';

/// Premium floating fuel status card — clean hierarchy, easy scan.
class VehicleDashboardPanel extends StatelessWidget {
  final FuelService fuel;
  final bool lowFuel;

  const VehicleDashboardPanel({
    super.key,
    required this.fuel,
    required this.lowFuel,
  });

  double get _litersPer100Km {
    return fuel.litersPer100Km;
  }

  @override
  Widget build(BuildContext context) {
    final percent = fuel.fuelPercent.clamp(0.0, 100.0);
    final remaining = fuel.remainingDistanceKm;
    final efficiency = _litersPer100Km;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: VisionProFloatingCard(
        borderRadius: LuxuryTokens.radiusLg,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        elevation: lowFuel ? 2 : 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top edge highlight — Vision Pro glass rim.
            Container(
              height: 1.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    LuxuryTokens.neonCyan.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.08),
                    LuxuryTokens.neonBlue.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _FuelPercentRing(
                  percent: percent,
                  lowFuel: lowFuel,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quãng đường còn',
                        style: VehicleUi.statLabel(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            remaining.toStringAsFixed(0),
                            style: VehicleUi.statValue(
                              color: LuxuryTokens.neonBlue,
                              size: 28,
                            ),
                          ),
                          Text(
                            'km',
                            style: VehicleUi.statValue(
                              color: LuxuryTokens.neonBlue,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Hiệu suất (tiêu hao)',
                        style: VehicleUi.statLabel(
                          color: VehicleUi.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            efficiency.toStringAsFixed(1),
                            style: VehicleUi.statValue(
                              color: VehicleUi.textPrimary,
                              size: 22,
                            ),
                          ),
                          Text(
                            'L/100km',
                            style: VehicleUi.statValue(
                              color: VehicleUi.textSecondary.withValues(alpha: 0.95),
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cập nhật theo GPS',
                        style: TextStyle(
                          color: VehicleUi.textSecondary.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lowFuel) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: VehicleUi.warningRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VehicleUi.radiusSm),
                  border: Border.all(
                    color: VehicleUi.warningRed.withValues(alpha: 0.35),
                  ),
                  boxShadow: LuxuryTokens.elevation(1, glow: VehicleUi.warningRed),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: VehicleUi.warningRed, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sắp hết xăng — tìm trạm gần nhất',
                        style: TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FuelPercentRing extends StatefulWidget {
  final double percent;
  final bool lowFuel;

  const _FuelPercentRing({required this.percent, required this.lowFuel});

  @override
  State<_FuelPercentRing> createState() => _FuelPercentRingState();
}

class _FuelPercentRingState extends State<_FuelPercentRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.lowFuel ? VehicleUi.warningRed : LuxuryTokens.neonBlue;
    final p = (widget.percent / 100).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.15 + _pulse.value * 0.2;
        return Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: active.withValues(alpha: glow),
                blurRadius: 18 + _pulse.value * 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: TweenAnimationBuilder<double>(
        key: ValueKey(widget.percent.toStringAsFixed(2)),
        tween: Tween<double>(begin: 0.0, end: p),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            foregroundPainter: _FuelRingPainter(
              progress: value,
              activeColor: active,
              trackColor: VehicleUi.textSecondary.withValues(alpha: 0.18),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: active,
                      height: 1.05,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Xăng còn lại',
                    style: VehicleUi.statLabel(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FuelRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _FuelRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 10;
    const stroke = 9.5;

    // Track (subtle, desaturated).
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    // Active segments with cinematic sweep.
    const sweepStart = -math.pi / 2;
    final sweepTotal = 2 * math.pi * progress;

    const segments = 20;
    const segAngle = (2 * math.pi) / segments;
    const gapFactor = 0.72; // creates breathing gaps (no heavy glow)

    final shader = SweepGradient(
      colors: [
        activeColor.withValues(alpha: 0.15),
        activeColor,
        activeColor.withValues(alpha: 0.6),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (int i = 0; i < segments; i++) {
      final a0 = sweepStart + i * segAngle;
      if (a0 > sweepStart + sweepTotal) break;

      const segSweep = segAngle * gapFactor;
      final a1 = a0 + segSweep;
      if (a1 > sweepStart + sweepTotal) {
        final remain = (sweepStart + sweepTotal) - a0;
        if (remain <= 0) break;
        // Clamp last segment.
        _drawArc(canvas, center, radius, a0, a0 + remain, stroke, shader);
      } else {
        _drawArc(canvas, center, radius, a0, a1, stroke, shader);
      }
    }
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double radius,
    double start,
    double end,
    double stroke,
    Shader shader,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      end - start,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FuelRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}

