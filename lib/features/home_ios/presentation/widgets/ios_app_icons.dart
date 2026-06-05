import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_squircle.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_typography.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_visual_tokens.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';

/// Icon Springboard — squircle, gradient iOS 18, bóng Apple.
class IosAppIconArt extends StatelessWidget {
  const IosAppIconArt({
    super.key,
    required this.app,
    required this.size,
  });

  final IosAppModel app;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (app.icon != null) {
      return IosSquircle.clip(
        size: size,
        child: SizedBox(width: size, height: size, child: app.icon),
      );
    }

    final spec = _specFor(app.id);

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: IosSquircle.shape(size),
        gradient: LinearGradient(
          begin: spec.gradientBegin,
          end: spec.gradientEnd,
          colors: spec.colors,
          stops: spec.stops ?? _evenStops(spec.colors.length),
        ),
        shadows: IosVisualTokens.iconShadow(size, spec.colors.first),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IosSquircle.clip(
            size: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
          ),
          Center(child: spec.builder(size)),
        ],
      ),
    );
  }

  static List<double> _evenStops(int n) =>
      List<double>.generate(n, (i) => i / (n - 1).clamp(1, n));

  _IconSpec _specFor(String id) => switch (id) {
        'fuel_tracker' => _IconSpec(
            const [Color(0xFF6BA3D6), Color(0xFF3A6FA0)],
            (s) => Icon(Icons.local_gas_station_rounded,
                color: Colors.white, size: s * 0.44),
          ),
        'maps' => _IconSpec(
            const [Color(0xFF7AD88A), Color(0xFF4DBF6A), Color(0xFF2E9A48)],
            (s) => _MapsGlyph(size: s),
            stops: const [0.0, 0.55, 1.0],
          ),
        'camera' => _IconSpec(
            const [Color(0xFFAEAEB2), Color(0xFF636366)],
            (s) => _CameraGlyph(size: s),
          ),
        'photos' => _IconSpec(
            const [Color(0xFFFFD060), Color(0xFFFF8A80), Color(0xFF9575CD)],
            (s) => _PhotosGlyph(size: s),
            stops: const [0.0, 0.5, 1.0],
            gradientBegin: Alignment.topLeft,
            gradientEnd: Alignment.bottomRight,
          ),
        'settings' => _IconSpec(
            const [Color(0xFFC7C7CC), Color(0xFF8E8E93)],
            (s) => _SettingsGlyph(size: s),
          ),
        'wallet' => _IconSpec(
            const [Color(0xFF2C2C2E), Color(0xFF48484A)],
            (s) => Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.92), size: s * 0.4),
          ),
        'mail' => _IconSpec(
            const [Color(0xFF1B9AFF), Color(0xFF64B5FF)],
            (s) => _MailGlyph(size: s),
          ),
        'notes' => _IconSpec(
            const [Color(0xFFFFE680), Color(0xFFFFC04D)],
            (s) => Icon(Icons.note_alt_rounded,
                color: Colors.white, size: s * 0.42),
          ),
        'calendar' => _IconSpec(
            const [Colors.white, Color(0xFFF5F5F7)],
            (s) => _CalendarAppIcon(size: s),
          ),
        'weather' => _IconSpec(
            const [Color(0xFF7AD8FF), Color(0xFF1A8CFF)],
            (s) => _WeatherGlyph(size: s),
          ),
        'phone' => _IconSpec(
            const [Color(0xFF3DD068), Color(0xFF28A745)],
            (s) => Icon(Icons.phone_rounded,
                color: Colors.white, size: s * 0.42),
          ),
        'messages' => _IconSpec(
            const [Color(0xFF3DD068), Color(0xFF34C759)],
            (s) => Icon(Icons.message_rounded,
                color: Colors.white, size: s * 0.42),
          ),
        'safari' => _IconSpec(
            const [Color(0xFF4DA3FF), Color(0xFF7EC8FF)],
            (s) => _SafariGlyph(size: s),
          ),
        'music' => _IconSpec(
            const [Color(0xFFFF6B8A), Color(0xFF7B8CFF)],
            (s) => Icon(Icons.music_note_rounded,
                color: Colors.white, size: s * 0.42),
          ),
        _ => _IconSpec(
            app.iconGradient ?? const [Color(0xFF636366), Color(0xFF1C1C1E)],
            (s) => Icon(app.iconData ?? Icons.apps_rounded,
                color: Colors.white, size: s * 0.42),
          ),
      };
}

class _IconSpec {
  const _IconSpec(
    this.colors,
    this.builder, {
    this.stops,
    this.gradientBegin = Alignment.topCenter,
    this.gradientEnd = Alignment.bottomCenter,
  });

  final List<Color> colors;
  final List<double>? stops;
  final Widget Function(double size) builder;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
}

/// Icon Calendar app — thanh đỏ trên + số ngày.
class _CalendarAppIcon extends StatelessWidget {
  const _CalendarAppIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[now.weekday % 7];

    return SizedBox(
      width: size * 0.72,
      height: size * 0.72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.08),
        child: Column(
          children: [
            Container(
              height: size * 0.2,
              width: double.infinity,
              color: const Color(0xFFFF3B30),
              alignment: Alignment.center,
              child: Text(
                weekday,
                style: IosTypography.calendarWeekday(size * 0.11).copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Text(
                    '${now.day}',
                    style: IosTypography.calendarDay(size * 0.24).copyWith(
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraGlyph extends StatelessWidget {
  const _CameraGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.5, size * 0.5),
      painter: _CameraPainter(),
    );
  }
}

class _CameraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.84, h * 0.58),
      Radius.circular(h * 0.12),
    );
    canvas.drawRRect(body, Paint()..color = Colors.white.withValues(alpha: 0.92));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.08, w * 0.44, h * 0.18),
        Radius.circular(h * 0.06),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );

    final lensR = w * 0.18;
    final lensCenter = Offset(w * 0.5, h * 0.52);
    canvas.drawCircle(
      lensCenter,
      lensR,
      Paint()..color = const Color(0xFF2C2C2E),
    );
    canvas.drawCircle(
      lensCenter,
      lensR * 0.72,
      Paint()..color = const Color(0xFF48484A),
    );
    canvas.drawCircle(
      lensCenter.translate(-lensR * 0.25, -lensR * 0.25),
      lensR * 0.18,
      Paint()..color = const Color(0xFF5AC8FA).withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SettingsGlyph extends StatelessWidget {
  const _SettingsGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.46, size * 0.46),
      painter: _SettingsPainter(),
    );
  }
}

class _SettingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.38;
    final innerR = size.width * 0.16;
    final tooth = size.width * 0.09;

    final path = Path();
    const teeth = 8;
    for (var i = 0; i < teeth; i++) {
      final a1 = (i / teeth) * 2 * math.pi - math.pi / 2;
      final a2 = ((i + 0.35) / teeth) * 2 * math.pi - math.pi / 2;
      final a3 = ((i + 0.65) / teeth) * 2 * math.pi - math.pi / 2;
      final a4 = ((i + 1) / teeth) * 2 * math.pi - math.pi / 2;

      path.lineTo(cx + (outerR + tooth) * math.cos(a1), cy + (outerR + tooth) * math.sin(a1));
      path.lineTo(cx + outerR * math.cos(a2), cy + outerR * math.sin(a2));
      path.lineTo(cx + outerR * math.cos(a3), cy + outerR * math.sin(a3));
      path.lineTo(cx + (outerR + tooth) * math.cos(a4), cy + (outerR + tooth) * math.sin(a4));
    }
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()..color = const Color(0xFF8E8E93),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      innerR * 0.55,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MailGlyph extends StatelessWidget {
  const _MailGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.48, size * 0.48),
      painter: _MailPainter(),
    );
  }
}

class _MailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.58),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.95));

    final flap = Path()
      ..moveTo(w * 0.1, h * 0.22)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.9, h * 0.22);
    canvas.drawPath(
      flap,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhotosGlyph extends StatelessWidget {
  const _PhotosGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.5, size * 0.5),
      painter: _PhotosPainter(),
    );
  }
}

class _PhotosPainter extends CustomPainter {
  static const _petalColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFFFFEB3B),
    Color(0xFF69F0AE),
    Color(0xFF40C4FF),
    Color(0xFF7C4DFF),
    Color(0xFFFF80AB),
    Color(0xFFFFAB40),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -h * 0.13),
          width: w * 0.18,
          height: h * 0.24,
        ),
        Paint()..color = _petalColors[i],
      );
      canvas.restore();
    }

    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.07,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapsGlyph extends StatelessWidget {
  const _MapsGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.46, size * 0.46),
      painter: _MapsPainter(),
    );
  }
}

class _MapsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.12, h * 0.18)
      ..lineTo(w * 0.88, h * 0.12)
      ..lineTo(w * 0.78, h * 0.88)
      ..lineTo(w * 0.22, h * 0.82)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawLine(
      Offset(w * 0.5, h * 0.14),
      Offset(w * 0.44, h * 0.86),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = w * 0.04,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeatherGlyph extends StatelessWidget {
  const _WeatherGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.44, size * 0.44),
      painter: _WeatherPainter(),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sun = Offset(w * 0.62, h * 0.38);
    canvas.drawCircle(sun, w * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.95));
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(sun.dx + w * 0.2 * math.cos(angle), sun.dy + w * 0.2 * math.sin(angle)),
        Offset(sun.dx + w * 0.28 * math.cos(angle), sun.dy + w * 0.28 * math.sin(angle)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = w * 0.045
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SafariGlyph extends StatelessWidget {
  const _SafariGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.46, size * 0.46),
      painter: _SafariPainter(),
    );
  }
}

class _SafariPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.42,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.14)
        ..lineTo(w * 0.58, h * 0.58)
        ..lineTo(w * 0.5, h * 0.5)
        ..lineTo(w * 0.42, h * 0.58)
        ..close(),
      Paint()..color = const Color(0xFFFF3B30),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.86)
        ..lineTo(w * 0.42, h * 0.42)
        ..lineTo(w * 0.5, h * 0.5)
        ..lineTo(w * 0.58, h * 0.42)
        ..close(),
      Paint()..color = const Color(0xFF0A84FF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
