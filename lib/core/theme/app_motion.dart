import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';

/// Motion design — shared axis, fade+slide, spring page routes.
abstract final class AppMotion {
  static const transitionDuration = LuxuryTokens.duration;
  static const reverseDuration = Duration(milliseconds: 280);

  /// Fade + slide up — auth & modal flows.
  static Route<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: true,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: LuxuryTokens.curve,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Shared axis horizontal — Stripe / Linear sibling navigation.
  static Route<T> sharedAxis<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: true,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final inCurve = CurvedAnimation(
          parent: animation,
          curve: LuxuryTokens.curve,
          reverseCurve: Curves.easeInCubic,
        );
        final outCurve = CurvedAnimation(
          parent: secondaryAnimation,
          curve: LuxuryTokens.curve,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: inCurve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(inCurve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.04, 0),
              ).animate(outCurve),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Spring scale entrance — cards & hero elements.
  static Animation<double> springScale(Animation<double> parent) {
    return Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: parent, curve: LuxuryTokens.springCurve),
    );
  }
}
