import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_visual_tokens.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/app_icon.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/wallpaper_widget.dart';

/// Dock iOS 26 — glass panel, luôn nằm trên cùng vùng đáy, không overflow.
class DockWidget extends ConsumerWidget {
  const DockWidget({
    super.key,
    required this.metrics,
    required this.onAppTap,
    required this.onAppLongPress,
  });

  final IosHomeMetrics metrics;
  final void Function(IosAppModel app, BuildContext iconContext) onAppTap;
  final VoidCallback onAppLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dock = ref.watch(homeDockProvider);
    final isEditMode = ref.watch(isEditModeProvider);
    final dockRadius = BorderRadius.circular(metrics.dockCornerRadius);
    final systemBottom = MediaQuery.paddingOf(context).bottom;
    final dockBottomInset = systemBottom > 0
        ? IosVisualTokens.dockGapAboveHomeIndicator * metrics.scale
        : metrics.dockBottomPadding;
    final iconSize =
        metrics.dockIconSize.clamp(0.0, metrics.dockHeight - 16 * metrics.scale);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.dockHorizontalInset,
          0,
          metrics.dockHorizontalInset,
          dockBottomInset,
        ),
        child: ClipRRect(
          borderRadius: dockRadius,
          clipBehavior: Clip.hardEdge,
          child: IosGlassHighlight(
            borderRadius: dockRadius,
            subtle: true,
            clipContent: true,
            child: IosGlassPanel(
              borderRadius: dockRadius,
              padding: EdgeInsets.symmetric(
                horizontal: metrics.columnSpacing * 0.35,
                vertical: (metrics.dockHeight - iconSize) * 0.5,
              ),
              opacity: IosVisualTokens.glassOpacityDock,
              blurSigma: IosVisualTokens.glassBlurStrong,
              saturate: true,
              bright: true,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28 * metrics.scale,
                  offset: Offset(0, 10 * metrics.scale),
                ),
              ],
              child: SizedBox(
                height: iconSize,
                child: Row(
                  children: List.generate(dock.length, (index) {
                    final app = dock[index];

                    Widget slot = Builder(
                      builder: (iconContext) {
                        return AppIcon(
                          app: app,
                          metrics: metrics,
                          size: iconSize,
                          showLabel: false,
                          isEditMode: isEditMode,
                          jiggleIndex: index,
                          enableDrag: isEditMode,
                          onLongPress: onAppLongPress,
                          onTap: () => onAppTap(app, iconContext),
                        );
                      },
                    );

                    if (isEditMode) {
                      slot = DragTarget<int>(
                        onWillAcceptWithDetails: (details) => details.data != index,
                        onAcceptWithDetails: (details) {
                          ref
                              .read(homeLayoutProvider.notifier)
                              .reorderDock(details.data, index);
                        },
                        builder: (context, candidate, rejected) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: candidate.isNotEmpty
                                  ? Border.all(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: slot,
                          );
                        },
                      );
                    }

                    return Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: slot,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
