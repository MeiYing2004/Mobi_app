import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Icon status bar vẽ tay theo phong cách iOS 18 / SF Symbols.
abstract final class IosStatusIcons {
  static Widget signalBars({required double height, Color color = Colors.white}) {
    return CustomPaint(
      size: Size(height * 1.05, height),
      painter: _SignalBarsPainter(color: color),
    );
  }

  static Widget wifi({required double size, Color color = Colors.white}) {
    return CustomPaint(
      size: Size(size, size * 0.72),
      painter: _WifiPainter(color: color),
    );
  }

  static Widget battery({
    required double height,
    Color color = Colors.white,
    double fill = 0.76,
  }) {
    return CustomPaint(
      size: Size(height * 1.55, height),
      painter: _BatteryPainter(color: color, fill: fill),
    );
  }
}

class _SignalBarsPainter extends CustomPainter {
  _SignalBarsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barCount = 4;
    final barW = size.width / (barCount * 1.48);
    final gap = barW * 0.38;
    final heights = [0.28, 0.44, 0.6, 0.78];

    for (var i = 0; i < barCount; i++) {
      final h = size.height * heights[i];
      final x = i * (barW + gap);
      final y = size.height - h;
      final r = barW * 0.22;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          Radius.circular(r),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalBarsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WifiPainter extends CustomPainter {
  _WifiPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height * 0.92;
    final maxR = size.width * 0.46;

    for (var i = 1; i <= 3; i++) {
      final r = maxR * (i / 3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        paint,
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.055,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _WifiPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BatteryPainter extends CustomPainter {
  _BatteryPainter({required this.color, required this.fill});

  final Color color;
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyW = size.width * 0.9;
    final bodyH = size.height;
    final capW = size.width * 0.1;
    final stroke = bodyH * 0.1;
    final radius = bodyH * 0.24;

    final border = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyW, bodyH),
      Radius.circular(radius),
    );
    canvas.drawRRect(bodyRect, border);

    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyW, bodyH * 0.32, capW, bodyH * 0.36),
      Radius.circular(radius * 0.5),
    );
    canvas.drawRRect(
      capRect,
      Paint()..color = color.withValues(alpha: 0.88),
    );

    final inset = stroke * 1.1;
    final fillW = (bodyW - inset * 2) * fill.clamp(0.08, 1.0);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, fillW, bodyH - inset * 2),
      Radius.circular(radius * 0.65),
    );
    canvas.drawRRect(
      fillRect,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fill != fill;
}
