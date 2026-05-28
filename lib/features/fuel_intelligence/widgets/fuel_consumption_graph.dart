import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/ios_design_tokens.dart';

class FuelGraphPoint {
  final double lPer100Km;
  final double? speedKmh;

  const FuelGraphPoint({required this.lPer100Km, this.speedKmh});
}

class FuelConsumptionGraph extends StatelessWidget {
  final List<FuelGraphPoint> points;
  final double minLPer100Km;
  final double maxLPer100Km;
  final int futureProjectionPoints;
  final double? arrivalFuelPercent;
  final double? emptyAfterKm;
  final double? routeDistanceKm;

  const FuelConsumptionGraph({
    super.key,
    required this.points,
    this.minLPer100Km = 2,
    this.maxLPer100Km = 20,
    this.futureProjectionPoints = 10,
    this.arrivalFuelPercent,
    this.emptyAfterKm,
    this.routeDistanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _FuelGraphPainter(
          points: points,
          minY: minLPer100Km,
          maxY: maxLPer100Km,
          futureProjectionPoints: futureProjectionPoints,
          arrivalFuelPercent: arrivalFuelPercent,
          emptyAfterKm: emptyAfterKm,
          routeDistanceKm: routeDistanceKm,
        ),
        size: const Size(double.infinity, 140),
      ),
    ).animate().fadeIn(duration: 240.ms);
  }
}

class _FuelGraphPainter extends CustomPainter {
  final List<FuelGraphPoint> points;
  final double minY;
  final double maxY;
  final int futureProjectionPoints;
  final double? arrivalFuelPercent;
  final double? emptyAfterKm;
  final double? routeDistanceKm;

  _FuelGraphPainter({
    required this.points,
    required this.minY,
    required this.maxY,
    required this.futureProjectionPoints,
    required this.arrivalFuelPercent,
    required this.emptyAfterKm,
    required this.routeDistanceKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final clip = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.clipRRect(clip);

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x1619D3FF),
          Color(0x0DFFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    if (points.length < 2) return;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = IosDesign.neonCyan;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = IosDesign.neonCyan.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = _mapY(points[i].lPer100Km, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth curve using quadratic bezier.
        final prevX = ((i - 1) / (points.length - 1)) * size.width;
        final prevY = _mapY(points[i - 1].lPer100Km, size.height);
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(midX, prevY, x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Future trend projection (dashed + dim).
    Offset? futureEnd;
    if (points.length >= 3 && futureProjectionPoints > 0) {
      final last = points.last.lPer100Km;
      final prev = points[points.length - 2].lPer100Km;
      final trend = (last - prev).clamp(-1.2, 1.2);

      final proj = Path();
      final startX = size.width;
      final startY = _mapY(last, size.height);
      proj.moveTo(startX, startY);
      for (var j = 1; j <= futureProjectionPoints; j++) {
        final t = j / futureProjectionPoints;
        final x = startX + t * (size.width * 0.38);
        final y = _mapY(last + trend * (j * 0.8), size.height);
        proj.lineTo(x, y);
        if (j == futureProjectionPoints) {
          futureEnd = Offset(x, y);
        }
      }

      final dashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = IosDesign.neonCyan.withValues(alpha: 0.35);
      _drawDashed(canvas, proj, dashPaint, dash: 6, gap: 6);
    }

    _paintThresholdAndArrival(canvas, size, futureEnd);
  }

  void _paintThresholdAndArrival(Canvas canvas, Size size, Offset? futureEnd) {
    // Empty threshold line (near top indicates high risk consumption).
    final thresholdY = _mapY(maxY * 0.82, size.height);
    final thresholdPaint = Paint()
      ..color = IosDesign.warningRed.withValues(alpha: 0.3)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      thresholdPaint,
    );

    if (futureEnd != null && arrivalFuelPercent != null) {
      final arrival = arrivalFuelPercent!.clamp(0.0, 100.0);
      final markerColor = arrival < 15 ? IosDesign.warningRed : IosDesign.neonCyan;
      final markerPaint = Paint()
        ..color = markerColor.withValues(alpha: 0.92)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(futureEnd, 3.8, markerPaint);
    }

    if (emptyAfterKm != null && routeDistanceKm != null && routeDistanceKm! > 0) {
      final ratio = (emptyAfterKm! / routeDistanceKm!).clamp(0.0, 1.0);
      final x = size.width * ratio;
      final dangerPaint = Paint()
        ..color = IosDesign.warningRed.withValues(alpha: 0.32)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), dangerPaint);
    }
  }

  double _mapY(double v, double h) {
    final clamped = v.clamp(minY, maxY);
    final t = (clamped - minY) / (maxY - minY);
    return h - (t * h);
  }

  @override
  bool shouldRepaint(covariant _FuelGraphPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.futureProjectionPoints != futureProjectionPoints ||
        oldDelegate.arrivalFuelPercent != arrivalFuelPercent ||
        oldDelegate.emptyAfterKm != emptyAfterKm ||
        oldDelegate.routeDistanceKm != routeDistanceKm;
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint,
      {required double dash, required double gap}) {
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        final seg = metric.extractPath(dist, dist + len);
        canvas.drawPath(seg, paint);
        dist += dash + gap;
      }
    }
  }
}

