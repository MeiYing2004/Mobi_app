import 'package:flutter/material.dart';

/// Bo góc kiểu Apple squircle (Continuous Superellipse).
abstract final class IosSquircle {
  static const double cornerRatio = 0.2237;

  static BorderRadius radius(double size) =>
      BorderRadius.circular(size * cornerRatio);

  static ShapeBorder shape(double size) => ContinuousRectangleBorder(
        borderRadius: radius(size),
      );

  static Path clipPath(Size size) {
    return shape(size.shortestSide).getOuterPath(Offset.zero & size);
  }

  static Widget clip({required double size, required Widget child}) {
    return ClipPath(
      clipper: _SquircleClipper(size),
      child: child,
    );
  }
}

class _SquircleClipper extends CustomClipper<Path> {
  _SquircleClipper(this.size);

  final double size;

  @override
  Path getClip(Size bounds) => IosSquircle.clipPath(Size(size, size));

  @override
  bool shouldReclip(covariant _SquircleClipper oldClipper) =>
      oldClipper.size != size;
}
