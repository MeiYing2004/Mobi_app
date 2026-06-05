import 'package:flutter/material.dart';

/// Inset do LauncherShell cung cấp — app con (Fuel Tracker) căn dưới Status Bar / Island.
class IosShellInsets extends InheritedWidget {
  const IosShellInsets({
    super.key,
    required this.top,
    required this.bottom,
    required super.child,
  });

  final double top;
  final double bottom;

  static IosShellInsets? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<IosShellInsets>();
  }

  static IosShellInsets of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'IosShellInsets not found above context');
    return result!;
  }

  @override
  bool updateShouldNotify(IosShellInsets oldWidget) {
    return top != oldWidget.top || bottom != oldWidget.bottom;
  }
}
