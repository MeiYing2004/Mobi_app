import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:fuel_tracker_app/core/theme/app_colors.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_haptics.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_spring.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_visual_tokens.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/group3_demo/group3_food_demo_screen.dart';
import 'package:fuel_tracker_app/shared/screens/home_screen.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_app_icons.dart';

/// Zoom mở/đóng app — spring UIKit, icon → fullscreen → icon.
class AppLaunchOverlay extends StatefulWidget {
  const AppLaunchOverlay({
    super.key,
    required this.app,
    required this.iconRect,
    required this.onClosed,
    this.dragOffset = 0,
  });

  final IosAppModel app;
  final Rect? iconRect;
  final VoidCallback onClosed;
  final double dragOffset;

  @override
  State<AppLaunchOverlay> createState() => AppLaunchOverlayState();
}

class AppLaunchOverlayState extends State<AppLaunchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _isClosing = false;

  static const _iconCornerRatio = IosVisualTokens.iconCornerRatio;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      value: 0,
      duration: IosSpring.nominalDuration,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await IosHaptics.appOpen();
      if (mounted) {
        await IosSpring.animate(
          _progress,
          target: 1,
          spring: IosSpring.openApp,
        );
      }
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> closeFromLauncher() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    await IosHaptics.appClose();
    await IosSpring.animate(
      _progress,
      target: 0,
      spring: IosSpring.closeApp,
      velocity: _progress.velocity,
    );
    if (mounted) widget.onClosed();
  }

  double get _t => _progress.value.clamp(0.0, 1.0);

  double get _iconOpacity => (1 - _t * 2.4).clamp(0.0, 1.0);

  double get _appOpacity => ((_t - 0.08) / 0.92).clamp(0.0, 1.0);

  Rect _targetRect(Size screen) => Offset.zero & screen;

  Rect _sourceRect(Size screen) {
    return widget.iconRect ??
        Rect.fromCenter(
          center: Offset(screen.width / 2, screen.height * 0.72),
          width: screen.width * 0.18,
          height: screen.width * 0.18,
        );
  }

  Rect _currentRect(Size screen) {
    return Rect.lerp(_sourceRect(screen), _targetRect(screen), _t) ??
        _targetRect(screen);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: _progress,
      child: RepaintBoundary(
        child: widget.app.isGroup3Demo
            ? const _Group3DemoAppHost()
            : const _FuelTrackerAppHost(),
      ),
      builder: (context, appChild) {
        final rect = _currentRect(screen);
        final drag = (widget.dragOffset / screen.height).clamp(0.0, 0.38);
        final dragScale = 1.0 - drag * 0.18;
        final radius = lerpDouble(rect.shortestSide * _iconCornerRatio, 0, _t) ?? 0;
        final top = rect.top + widget.dragOffset * (1 - _t);

        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_t > 0.02)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: (0.42 * _t).clamp(0.0, 0.42)),
                  ),
                ),
              Positioned(
                left: rect.left,
                top: top,
                width: rect.width,
                height: rect.height,
                child: RepaintBoundary(
                  child: Transform.scale(
                    scale: dragScale,
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          OverflowBox(
                            minWidth: screen.width,
                            maxWidth: screen.width,
                            minHeight: screen.height,
                            maxHeight: screen.height,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: screen.width,
                              height: screen.height,
                              child: Opacity(
                                opacity: _appOpacity,
                                child: appChild,
                              ),
                            ),
                          ),
                          if (_iconOpacity > 0.01)
                            Opacity(
                              opacity: _iconOpacity,
                              child: IosAppIconArt(
                                app: widget.app,
                                size: rect.width,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Group3DemoAppHost extends StatelessWidget {
  const _Group3DemoAppHost();

  @override
  Widget build(BuildContext context) {
    // Navigator riêng — Drawer / Sheet không tràn lên Home iOS bên dưới.
    return const ColoredBox(
      color: AppColors.background,
      child: _Group3DemoNavigator(),
    );
  }
}

class _Group3DemoNavigator extends StatefulWidget {
  const _Group3DemoNavigator();

  @override
  State<_Group3DemoNavigator> createState() => _Group3DemoNavigatorState();
}

class _Group3DemoNavigatorState extends State<_Group3DemoNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Group3FoodDemoScreen(),
      ),
    );
  }
}

class _FuelTrackerAppHost extends StatelessWidget {
  const _FuelTrackerAppHost();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.backgroundDark,
      child: _FuelTrackerNavigator(),
    );
  }
}

class _FuelTrackerNavigator extends StatefulWidget {
  const _FuelTrackerNavigator();

  @override
  State<_FuelTrackerNavigator> createState() => _FuelTrackerNavigatorState();
}

class _FuelTrackerNavigatorState extends State<_FuelTrackerNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomeScreen(inLauncherMode: true),
      ),
    );
  }
}
