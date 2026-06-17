import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_haptics.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_typography.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/parallax_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/system_overlay_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/app_library_page.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/control_center_overlay.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/dock_widget.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/home_icon_grid.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_gesture_layer.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/notification_center_overlay.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/spotlight_overlay.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_home_theme.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/wallpaper_widget.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';

/// Màn hình Home — tách layer để giảm rebuild khi mở app / đổi trang.
class IosHomeScreen extends ConsumerWidget {
  const IosHomeScreen({super.key, required this.onLaunchApp});

  final void Function(IosAppModel app, Rect? iconRect) onLaunchApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = IosHomeMetrics.of(context);

    return IosHomeTheme(
      child: Consumer(
        builder: (context, ref, child) {
          final isAppOpen = ref.watch(isAppOpenProvider);
          final overlay = ref.watch(systemOverlayProvider);
          final gesturesEnabled =
              !isAppOpen && overlay == IosSystemOverlay.none;
          return IosGestureLayer(
            metrics: metrics,
            enabled: gesturesEnabled,
            child: child!,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const RepaintBoundary(child: _WallpaperLayer()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: metrics.dockZoneHeight,
              child: RepaintBoundary(
                child: _HomePagesLayer(
                  metrics: metrics,
                  onLaunchApp: onLaunchApp,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: metrics.pageDotsBottomOffset,
              child: RepaintBoundary(
                child: _PageDotsLayer(metrics: metrics),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: _DockLayer(
                  metrics: metrics,
                  onLaunchApp: onLaunchApp,
                ),
              ),
            ),
            _EditModeBar(metrics: metrics),
            RepaintBoundary(
              child: _SystemOverlaysLayer(onLaunchApp: onLaunchApp),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallpaper — parallax đứng yên khi app mở.
class _WallpaperLayer extends ConsumerWidget {
  const _WallpaperLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frozen = ref.watch(isAppOpenProvider);
    if (frozen) {
      return const _CachedWallpaperBody(offset: Offset.zero);
    }
    final parallax = ref.watch(parallaxProvider);
    return _CachedWallpaperBody(
      offset: Offset(
        parallax.dx.clamp(-6.0, 6.0),
        parallax.dy.clamp(-6.0, 6.0),
      ),
    );
  }
}

class _CachedWallpaperBody extends StatelessWidget {
  const _CachedWallpaperBody({required this.offset});

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: const WallpaperBackground(),
    );
  }
}

class _HomePagesLayer extends ConsumerStatefulWidget {
  const _HomePagesLayer({
    required this.metrics,
    required this.onLaunchApp,
  });

  final IosHomeMetrics metrics;
  final void Function(IosAppModel app, Rect? iconRect) onLaunchApp;

  @override
  ConsumerState<_HomePagesLayer> createState() => _HomePagesLayerState();
}

class _HomePagesLayerState extends ConsumerState<_HomePagesLayer> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleAppTap(IosAppModel app, BuildContext iconContext) {
    if (app.isLaunchable) {
      widget.onLaunchApp(app, _globalRect(iconContext));
      return;
    }
    IosHaptics.selection();
    _showPlaceholder(app.name);
  }

  void _handleLongPress() {
    IosHaptics.medium();
    ref.read(launcherProvider.notifier).enterEditMode();
  }

  Rect? _globalRect(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _showPlaceholder(String appName) {
    AppToastService.info(
      title: 'Ứng dụng chưa khả dụng',
      message: '$appName chưa được cài đặt',
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final homePageCount = ref.watch(homePageCountProvider);
    final totalPages = homePageCount + 1;
    final isEditMode = ref.watch(isEditModeProvider);

    return Column(
      children: [
        SizedBox(height: metrics.shellTopInset),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: isEditMode
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            onPageChanged: ref.read(launcherProvider.notifier).setPage,
            itemCount: totalPages,
            itemBuilder: (context, index) {
              if (index == homePageCount) {
                return AppLibraryPage(
                  metrics: metrics,
                  onAppTap: _handleAppTap,
                );
              }
              return SingleChildScrollView(
                physics: isEditMode
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: metrics.contentBottomClearance -
                      metrics.dockZoneHeight,
                ),
                child: HomeIconGrid(
                  metrics: metrics,
                  pageIndex: index,
                  onAppTap: _handleAppTap,
                  onAppLongPress: _handleLongPress,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PageDotsLayer extends ConsumerWidget {
  const _PageDotsLayer({required this.metrics});

  final IosHomeMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homePageCount = ref.watch(homePageCountProvider);
    final currentPage = ref.watch(currentPageProvider);

    return IgnorePointer(
      child: HomePageDots(
        count: homePageCount + 1,
        current: currentPage,
        metrics: metrics,
      ),
    );
  }
}

class _DockLayer extends ConsumerWidget {
  const _DockLayer({
    required this.metrics,
    required this.onLaunchApp,
  });

  final IosHomeMetrics metrics;
  final void Function(IosAppModel app, Rect? iconRect) onLaunchApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void handleTap(IosAppModel app, BuildContext ctx) {
      if (app.isLaunchable) {
        final box = ctx.findRenderObject() as RenderBox?;
        final rect = box != null && box.hasSize
            ? box.localToGlobal(Offset.zero) & box.size
            : null;
        onLaunchApp(app, rect);
        return;
      }
      IosHaptics.selection();
    }

    return DockWidget(
      metrics: metrics,
      onAppTap: handleTap,
      onAppLongPress: () {
        IosHaptics.medium();
        ref.read(launcherProvider.notifier).enterEditMode();
      },
    );
  }
}

class _EditModeBar extends ConsumerWidget {
  const _EditModeBar({required this.metrics});

  final IosHomeMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(isEditModeProvider);
    if (!isEditMode) return const SizedBox.shrink();

    return Positioned(
      top: metrics.shellTopInset + 4,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: () => ref.read(launcherProvider.notifier).exitEditMode(),
          child: Center(
            child: Text(
              'Hoàn tất',
              style: IosTypography.widgetTitle(metrics.iconSize * 0.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemOverlaysLayer extends ConsumerWidget {
  const _SystemOverlaysLayer({required this.onLaunchApp});

  final void Function(IosAppModel app, Rect? iconRect) onLaunchApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(systemOverlayProvider);
    final metrics = IosHomeMetrics.of(context);

    return switch (overlay) {
      IosSystemOverlay.spotlight => SpotlightOverlay(
          metrics: metrics,
          onDismiss: () => ref.read(systemOverlayProvider.notifier).dismiss(),
          onAppSelected: (app) {
            ref.read(systemOverlayProvider.notifier).dismiss();
            if (app.isLaunchable) {
              onLaunchApp(app, null);
            }
          },
        ),
      IosSystemOverlay.controlCenter => ControlCenterOverlay(
          metrics: metrics,
          onDismiss: () => ref.read(systemOverlayProvider.notifier).dismiss(),
        ),
      IosSystemOverlay.notificationCenter => NotificationCenterOverlay(
          metrics: metrics,
          onDismiss: () => ref.read(systemOverlayProvider.notifier).dismiss(),
        ),
      IosSystemOverlay.none => const SizedBox.shrink(),
    };
  }
}
