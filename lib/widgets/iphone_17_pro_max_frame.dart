import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/ios_design_tokens.dart';

/// Màu khung iPhone 17 Pro Max.
enum IPhone17FrameColor {
  titaniumBlack,
  naturalTitanium,
}

/// Khung thiết bị iPhone 17 Pro Max — bọc nội dung app trong màn hình bo góc.
///
/// Tỷ lệ màn hình chuẩn: **1290 × 2796** (portrait).
class IPhone17ProMaxFrame extends StatelessWidget {
  const IPhone17ProMaxFrame({
    super.key,
    required this.child,
    this.frameColor = IPhone17FrameColor.titaniumBlack,
    this.enabled = true,
    this.showDynamicIsland = true,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final IPhone17FrameColor frameColor;
  final bool enabled;
  final bool showDynamicIsland;
  final EdgeInsetsGeometry padding;

  /// Tỷ lệ màn hình iPhone 17 Pro Max (width / height).
  static const double screenAspectRatio =
      IPhone17ProMaxGeometry.logicalWidth /
      IPhone17ProMaxGeometry.logicalHeight;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return ColoredBox(
      color: const Color(0xFF050506),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: IosDesign.ambientGradient),
        child: SafeArea(
          child: Padding(
            padding: padding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _PhoneLayout.fromConstraints(constraints);
                return Center(
                  child: SizedBox(
                    width: layout.outerWidth,
                    height: layout.outerHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _DeviceShadow(layout: layout),
                        _PhoneBody(
                          layout: layout,
                          frameColor: frameColor,
                          showDynamicIsland: showDynamicIsland,
                          child: child,
                        ),
                        ..._sideButtons(layout: layout, frameColor: frameColor),
                      ],
                    ),
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

class IPhone17ProMaxGeometry {
  IPhone17ProMaxGeometry._();

  static const double logicalWidth = 1290;
  static const double logicalHeight = 2796;

  // Tuned to iPhone 15 Pro-like proportions (thin bezels, rounder corners).
  // Thinner frame for iPhone 15 Pro Max-like screen dominance.
  static const double bezelRatio = 0.023;
  static const double outerRadiusRatio = 0.152;
  static const double screenRadiusRatio = 0.132;
  static const double islandWidthRatio = 0.34;
  static const double islandHeightRatio = 0.026;
  static const double islandTopRatio = 0.015;
}

class _PhoneLayout {
  _PhoneLayout({
    required this.outerWidth,
    required this.outerHeight,
    required this.bezel,
    required this.outerRadius,
    required this.screenRadius,
  });

  final double outerWidth;
  final double outerHeight;
  final double bezel;
  final double outerRadius;
  final double screenRadius;

  double get screenWidth => outerWidth - bezel * 2;
  double get screenHeight => outerHeight - bezel * 2;

  static _PhoneLayout fromConstraints(BoxConstraints constraints) {
    const aspect = IPhone17ProMaxFrame.screenAspectRatio;
    final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 430.0;
    final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 932.0;

    var outerH = maxH;
    var outerW = outerH * aspect;

    if (outerW > maxW) {
      outerW = maxW;
      outerH = outerW / aspect;
    }

    final bezel = outerW * IPhone17ProMaxGeometry.bezelRatio;
    final outerRadius = outerW * IPhone17ProMaxGeometry.outerRadiusRatio;
    final screenRadius = outerW * IPhone17ProMaxGeometry.screenRadiusRatio;

    return _PhoneLayout(
      outerWidth: outerW,
      outerHeight: outerH,
      bezel: bezel,
      outerRadius: outerRadius,
      screenRadius: screenRadius,
    );
  }
}

class _DeviceShadow extends StatelessWidget {
  const _DeviceShadow({required this.layout});

  final _PhoneLayout layout;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, layout.outerHeight * 0.02),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.outerRadius),
            boxShadow: [
              BoxShadow(
                // Blue ambient glow (marketing render look)
                color: const Color(0xFF008CFF).withValues(alpha: 0.16),
                blurRadius: layout.outerWidth * 0.18,
                spreadRadius: layout.outerWidth * 0.01,
                offset: Offset(0, layout.outerHeight * 0.02),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: layout.outerWidth * 0.12,
                spreadRadius: layout.outerWidth * 0.01,
                offset: Offset(0, layout.outerHeight * 0.03),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: layout.outerWidth * 0.04,
                offset: Offset(layout.outerWidth * 0.02, layout.outerHeight * 0.015),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneBody extends StatelessWidget {
  const _PhoneBody({
    required this.layout,
    required this.frameColor,
    required this.showDynamicIsland,
    required this.child,
  });

  final _PhoneLayout layout;
  final IPhone17FrameColor frameColor;
  final bool showDynamicIsland;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _FramePalette.of(frameColor);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SizedBox(
      width: layout.outerWidth,
      height: layout.outerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // === Layer 1: outer titanium shell (multi-layer, realistic) ===
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(layout.outerRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: palette.frameGradient,
                        stops: const [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Brushed metal micro-stripes (very subtle).
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _BrushedMetalPainter(
                        intensity: 0.028,
                        tilt: 0.16,
                      ),
                    ),
                  ),
                  // Curved environment reflections on the shell.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1, -0.6),
                          end: const Alignment(0.9, 0.9),
                          colors: [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.02),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.22, 0.7],
                        ),
                      ),
                    ),
                  ),
                  // Soft studio key light (top-left) + faint cool rim light (right edge).
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1.0, -1.0),
                          end: const Alignment(0.2, 0.6),
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.62],
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            const Color(0xFF6EE7FF).withValues(alpha: 0.045),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.22],
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.55, -0.55),
                          radius: 1.15,
                          colors: [
                            Colors.white.withValues(alpha: 0.09),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6],
                        ),
                      ),
                    ),
                  ),
                  // Directional highlight streak (non-uniform lighting).
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-0.65, -1.0),
                          end: const Alignment(1.0, 0.15),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.28, 0.5, 0.74],
                        ),
                      ),
                    ),
                  ),
                  // Metallic edge ring (reflective inner edge).
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.all(layout.bezel * 0.30),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            layout.outerRadius - layout.bezel * 0.40,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.09),
                            width: 0.9,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.20),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Warm micro reflection along lower titanium edge (subtle).
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: layout.bezel * 1.1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [
                              const Color(0xFFFFD6A5).withValues(alpha: 0.035),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.75],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom bounce light (cool blue, very soft).
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: layout.outerHeight * 0.22,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.0, 1.0),
                            radius: 1.05,
                            colors: [
                              const Color(0xFF008CFF).withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.72],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tiny top edge reflection (Apple-like).
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: layout.bezel * 0.55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Micro imperfections: faint luminance variation + tiny irregularities.
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _MicroNoisePainter(
                        opacity: 0.035,
                        density: 0.22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === Layer 2: inner black bezel (ultra thin, top slightly thicker) ===
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(layout.bezel * 0.68),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(layout.screenRadius + 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF030305),
                    boxShadow: [
                      // Inner shadow for OLED depth
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.85),
                        blurRadius: layout.outerWidth * 0.06,
                        spreadRadius: -layout.outerWidth * 0.01,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // === Layer 3: OLED screen with asymmetric bezels ===
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: layout.bezel * 0.92,
                right: layout.bezel * 0.92,
                bottom: layout.bezel * 0.94,
                top: layout.bezel * 1.14, // slightly thicker top bezel
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(layout.screenRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      removeBottom: true,
                      child: Builder(
                        builder: (context) {
                          final mq = MediaQuery.of(context);
                          final topInset = math.max(28.0, layout.screenHeight * 0.048);
                          final bottomInset =
                              math.max(18.0, layout.screenHeight * 0.028);
                          return MediaQuery(
                            data: mq.copyWith(
                              size: Size(layout.screenWidth, layout.screenHeight),
                              padding: EdgeInsets.only(
                                top: topInset,
                                bottom: bottomInset,
                              ),
                              viewPadding: EdgeInsets.only(
                                top: topInset,
                                bottom: bottomInset,
                              ),
                            ),
                            child: ColoredBox(
                              color: isLight ? Colors.white : Colors.black,
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                    // OLED edge vignette + black depth falloff (edge-only, not crushed).
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.05,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: isLight ? 0.02 : 0.12),
                            ],
                            stops: isLight ? const [0.88, 1.0] : const [0.78, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Subsurface glass diffusion (ultra subtle).
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.1, -0.35),
                            radius: 1.25,
                            colors: [
                              Colors.white.withValues(alpha: 0.035),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.62],
                          ),
                        ),
                      ),
                    ),
                    // === Layer 4: glass reflections (screen gloss) ===
                    IgnorePointer(
                      child: _ScreenGlassReflection(isLight: isLight),
                    ),
                    // Long soft diagonal sheen (<5% opacity).
                    const IgnorePointer(
                      child: _DiagonalSheen(),
                    ),
                    // Curved edge light rolloff (glass curvature illusion).
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.03),
                            ],
                            stops: const [0.0, 0.14, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Thin bezel line to separate glass from frame.
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(layout.screenRadius),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                    // Inset shadow to make UI feel embedded.
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(layout.screenRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.28),
                              blurRadius: layout.outerWidth * 0.05,
                              spreadRadius: -layout.outerWidth * 0.024,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tiny gap feel between bezel and OLED (optical separation).
                    IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.all(1.2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(layout.screenRadius - 1.2),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.34),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: _IosHomeIndicator(),
                    ),
                    // Status bar on top of glass overlays (no sheen artifacts on time).
                    Positioned(
                      top: layout.screenHeight * 0.016,
                      left: layout.screenWidth * 0.06,
                      right: layout.screenWidth * 0.06,
                      child: _IosStatusBar(
                        islandWidth:
                            layout.screenWidth *
                            IPhone17ProMaxGeometry.islandWidthRatio,
                        isLight: isLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (showDynamicIsland)
            Positioned(
              top: layout.bezel +
                  layout.screenHeight * IPhone17ProMaxGeometry.islandTopRatio,
              left: 0,
              right: 0,
              child: Center(
                child: _DynamicIsland(
                  width: layout.screenWidth * IPhone17ProMaxGeometry.islandWidthRatio,
                  height: math.max(
                    28,
                    layout.screenWidth * IPhone17ProMaxGeometry.islandHeightRatio,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScreenGlassReflection extends StatelessWidget {
  const _ScreenGlassReflection({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.9, -1),
              end: const Alignment(0.8, 0.95),
              colors: [
                Colors.white.withValues(alpha: isLight ? 0.06 : 0.11),
                Colors.white.withValues(alpha: isLight ? 0.02 : 0.035),
                Colors.transparent,
              ],
              stops: const [0.0, 0.26, 0.68],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.45, -0.75),
              radius: 1.15,
              colors: [
                Colors.white.withValues(alpha: isLight ? 0.045 : 0.075),
                Colors.transparent,
              ],
              stops: const [0.0, 0.62],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: isLight ? 0.0 : 0.06),
                Colors.transparent,
                Colors.black.withValues(alpha: isLight ? 0.0 : 0.09),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _IosStatusBar extends StatefulWidget {
  const _IosStatusBar({required this.islandWidth, required this.isLight});

  final double islandWidth;
  final bool isLight;

  @override
  State<_IosStatusBar> createState() => _IosStatusBarState();
}

class _IosStatusBarState extends State<_IosStatusBar> {
  Timer? _clockTimer;
  late String _timeLabel;

  static String _vietnamTimeLabel() {
    final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
    final minute = vn.minute.toString().padLeft(2, '0');
    return '${vn.hour}:$minute';
  }

  @override
  void initState() {
    super.initState();
    _timeLabel = _vietnamTimeLabel();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final next = _vietnamTimeLabel();
      if (next != _timeLabel) setState(() => _timeLabel = next);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sideGap = widget.islandWidth * 0.56;
    final fg = widget.isLight ? const Color(0xFF0B1220) : Colors.white;
    return IgnorePointer(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: sideGap * 0.1),
              child: Text(
                _timeLabel,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  height: 1.1,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
            ),
          ),
          SizedBox(width: sideGap),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SignalBarsIcon(color: fg),
                const SizedBox(width: 5),
                _WifiGlyphIcon(color: fg),
                const SizedBox(width: 5),
                _BatteryGlyphIcon(color: fg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBarsIcon extends StatelessWidget {
  const _SignalBarsIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 17,
      height: 11,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(3, 0.55),
          const SizedBox(width: 1.1),
          _bar(5, 0.72),
          const SizedBox(width: 1.1),
          _bar(7, 0.86),
          const SizedBox(width: 1.1),
          _bar(9, 1.0),
        ],
      ),
    );
  }

  Widget _bar(double h, double alpha) {
    return Container(
      width: 2.2,
      height: h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(1.2),
      ),
    );
  }
}

class _WifiGlyphIcon extends StatelessWidget {
  const _WifiGlyphIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.wifi_rounded, size: 12.5, color: color);
  }
}

class _BatteryGlyphIcon extends StatelessWidget {
  const _BatteryGlyphIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 11,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Container(
            width: 21,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: color.withValues(alpha: 0.88),
                width: 1.1,
              ),
            ),
            padding: const EdgeInsets.all(1.3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 12.5,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(1.7),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 2,
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IosHomeIndicator extends StatelessWidget {
  const _IosHomeIndicator();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 140,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagonalSheen extends StatelessWidget {
  const _DiagonalSheen();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiagonalSheenPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _DiagonalSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      -size.width * 0.4,
      size.height * 0.05,
      size.width * 1.4,
      size.height * 0.34,
    );
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide * 0.18));

    canvas.save();
    canvas.translate(size.width * 0.18, size.height * 0.08);
    canvas.rotate(-0.22);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0.18, 0.5, 0.82],
      ).createShader(rrect.outerRect);

    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalSheenPainter oldDelegate) => false;
}

class _BrushedMetalPainter extends CustomPainter {
  _BrushedMetalPainter({required this.intensity, required this.tilt});

  final double intensity;
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;

    // Draw subtle diagonal stripes to mimic brushed titanium.
    final step = math.max(6.0, size.width * 0.02);
    final diag = size.height / (1 + tilt.abs());
    for (double x = -size.height; x < size.width + size.height; x += step) {
      // Slight non-uniform intensity to avoid "perfect" Flutter look.
      final t = ((x / step) % 7).abs() / 7.0;
      paint.color =
          Colors.white.withValues(alpha: (intensity * (0.85 + 0.35 * t)));
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + diag * tilt, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrushedMetalPainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.tilt != tilt;
}

class _MicroNoisePainter extends CustomPainter {
  _MicroNoisePainter({required this.opacity, required this.density});

  final double opacity;
  final double density;

  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic pseudo-noise: a few tiny specks + faint bands.
    final speckPaint = Paint()..style = PaintingStyle.fill;
    final bandPaint = Paint()..style = PaintingStyle.stroke;

    final count = (size.width * size.height * 0.00005 * density).clamp(18, 90);
    for (int i = 0; i < count; i++) {
      final fx = (i * 73) % 997 / 997.0;
      final fy = (i * 191) % 991 / 991.0;
      final x = fx * size.width;
      final y = fy * size.height;
      final a = opacity * (0.6 + 0.4 * (((i * 17) % 13) / 13.0));
      speckPaint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 0.45 + (i % 3) * 0.22, speckPaint);
    }

    bandPaint
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: opacity * 0.35);
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.12 + i * 0.23);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bandPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MicroNoisePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.density != density;
}

class _FramePalette {
  const _FramePalette({
    required this.frameGradient,
    required this.edge,
    required this.button,
    required this.buttonShadow,
    required this.highlight,
    required this.antenna,
  });

  final List<Color> frameGradient;
  final Color edge;
  final Color button;
  final Color buttonShadow;
  final Color highlight;
  final Color antenna;

  static _FramePalette of(IPhone17FrameColor color) {
    switch (color) {
      case IPhone17FrameColor.titaniumBlack:
        return const _FramePalette(
          frameGradient: [
            Color(0xFF4A4A4E),
            Color(0xFF2A2A2C),
            Color(0xFF1C1C1E),
            Color(0xFF3D3D40),
          ],
          edge: Color(0xFF5C5C60),
          button: Color(0xFF353538),
          buttonShadow: Color(0xFF0A0A0B),
          highlight: Color(0x66FFFFFF),
          antenna: Color(0xFF6E6E73),
        );
      case IPhone17FrameColor.naturalTitanium:
        return const _FramePalette(
          frameGradient: [
            Color(0xFF9A9590),
            Color(0xFF7A7570),
            Color(0xFF5E5A56),
            Color(0xFF8A8580),
          ],
          edge: Color(0xFFB8B2AC),
          button: Color(0xFF6E6964),
          buttonShadow: Color(0xFF3A3835),
          highlight: Color(0x55FFFFFF),
          antenna: Color(0xFF9A9590),
        );
    }
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF020203),
        borderRadius: BorderRadius.circular(height),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle glossy top highlight.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
            // Inner edge ring
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF0C0C0E),
                  width: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _sideButtons({
  required _PhoneLayout layout,
  required IPhone17FrameColor frameColor,
}) {
  final palette = _FramePalette.of(frameColor);
  final btnW = layout.bezel * 0.55;
  final btnH = layout.outerHeight * 0.075;
  final shortH = layout.outerHeight * 0.045;
  final radius = btnW * 0.35;

  Widget button(double height, {bool action = false}) {
    return _PhysicalButton(
      width: btnW,
      height: height,
      radius: radius,
      color: palette.button,
      shadowColor: palette.buttonShadow,
      actionStyle: action,
    );
  }

  final leftX = -btnW * 0.85;
  final rightX = layout.outerWidth + btnW * 0.12;

  return [
    Positioned(
      left: leftX,
      top: layout.outerHeight * 0.2,
      child: button(shortH, action: true),
    ),
    Positioned(
      left: leftX,
      top: layout.outerHeight * 0.31,
      child: button(btnH * 0.55),
    ),
    Positioned(
      left: leftX,
      top: layout.outerHeight * 0.38,
      child: button(btnH * 0.55),
    ),
    Positioned(
      left: rightX,
      top: layout.outerHeight * 0.28,
      child: button(btnH),
    ),
  ];
}

class _PhysicalButton extends StatelessWidget {
  const _PhysicalButton({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
    required this.shadowColor,
    this.actionStyle = false,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;
  final Color shadowColor;
  final bool actionStyle;

  @override
  Widget build(BuildContext context) {
    // Add a tiny mounting gap + recessed shadow (buttons feel embedded).
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: 1.4,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 5,
                    offset: const Offset(1.5, 2.5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 1.4, // tiny gap to the frame
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color.withValues(alpha: actionStyle ? 0.96 : 0.90),
                          color.withValues(alpha: 0.74),
                          color.withValues(alpha: 0.94),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Specular edge highlight (thin, not uniform).
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.2, -1),
                        end: const Alignment(0.6, 1),
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.75],
                      ),
                    ),
                  ),
                  // Inner edge ring
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: shadowColor.withValues(alpha: 0.55),
                        width: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bọc [MaterialApp] — dùng trong `builder` để khung áp dụng mọi màn hình.
class IPhone17ProMaxAppShell extends StatelessWidget {
  const IPhone17ProMaxAppShell({
    super.key,
    required this.child,
    this.frameColor = IPhone17FrameColor.titaniumBlack,
    this.enabled,
  });

  final Widget? child;
  final IPhone17FrameColor frameColor;

  /// Mặc định: bật trên desktop (Windows/macOS/Linux/web), tắt trên iOS/Android thật.
  final bool? enabled;

  bool get _shouldShowFrame {
    if (enabled != null) return enabled!;
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    return IPhone17ProMaxFrame(
      enabled: _shouldShowFrame,
      frameColor: frameColor,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
