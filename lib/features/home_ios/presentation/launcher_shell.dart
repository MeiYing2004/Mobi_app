import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_indicator_controller.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/system_overlay_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/pages/ios_home_screen.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/app_launch_overlay.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_launcher_chrome.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_home_theme.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_shell_insets.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_system_sync.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/shell_home_indicator.dart';

/// LauncherShell = OS iOS: StatusBar, Island, Home, App overlay, Home Indicator.
class LauncherShell extends ConsumerStatefulWidget {
  const LauncherShell({super.key});

  @override
  ConsumerState<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends ConsumerState<LauncherShell> {
  final _overlayKey = GlobalKey<AppLaunchOverlayState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(homeIndicatorDragProvider.notifier)
          .registerDismissHandler(_closeOpenApp);
    });
  }

  Future<void> _closeOpenApp() async {
    final overlay = _overlayKey.currentState;
    if (overlay != null) {
      await overlay.closeFromLauncher();
    } else {
      ref.read(launcherProvider.notifier).closeApp();
    }
  }

  void _handleLaunchApp(IosAppModel app, Rect? rect) {
    ref.read(systemOverlayProvider.notifier).dismiss();
    ref.read(launcherProvider.notifier).openApp(app, iconRect: rect);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = IosHomeMetrics.of(context);

    return IosHomeTheme(
      child: IosShellInsets(
        top: metrics.shellTopInset,
        bottom: metrics.shellBottomInset,
        child: IosSystemSync(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              IosHomeScreen(onLaunchApp: _handleLaunchApp),
              _AppLaunchOverlayLayer(overlayKey: _overlayKey),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: IosLauncherChrome(metrics: metrics),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  child: ShellHomeIndicator(
                    screenWidth: metrics.screenWidth,
                    bottomPadding: metrics.homeIndicatorBottomInset,
                    pillWidth: metrics.homeIndicatorWidth,
                    pillHeight: metrics.homeIndicatorHeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay riêng — chỉ layer này rebuild khi drag / mở app.
class _AppLaunchOverlayLayer extends ConsumerWidget {
  const _AppLaunchOverlayLayer({required this.overlayKey});

  final GlobalKey<AppLaunchOverlayState> overlayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAppOpen = ref.watch(isAppOpenProvider);
    if (!isAppOpen) return const SizedBox.shrink();

    final openApp = ref.watch(openAppProvider);
    if (openApp == null) return const SizedBox.shrink();

    final iconRect = ref.watch(iconLaunchRectProvider);
    final dragOffset = ref.watch(homeIndicatorDragProvider);

    return AppLaunchOverlay(
      key: overlayKey,
      app: openApp,
      iconRect: iconRect,
      dragOffset: dragOffset,
      onClosed: () {
        ref.read(homeIndicatorDragProvider.notifier).resetDrag();
        ref.read(launcherProvider.notifier).closeApp();
      },
    );
  }
}
