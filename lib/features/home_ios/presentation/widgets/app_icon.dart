import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_typography.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_app_icons.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_spring_widgets.dart';

/// Icon Springboard — spring press 0.96, jiggle edit mode.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.app,
    required this.metrics,
    this.size,
    this.showLabel = true,
    this.isEditMode = false,
    this.jiggleIndex = 0,
    this.onTap,
    this.onLongPress,
    this.enableDrag = false,
    this.onDragStarted,
    this.onDragEnded,
    this.showBadge = false,
  });

  final IosAppModel app;
  final IosHomeMetrics metrics;
  final double? size;
  final bool showLabel;
  final bool isEditMode;
  final int jiggleIndex;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableDrag;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? metrics.iconSize;
    final labelSize = metrics.labelFontSize;

    Widget iconBody = IosAppIconArt(app: app, size: iconSize);

    if (isEditMode) {
      iconBody = iconBody
          .animate(
            onPlay: (c) => c.repeat(reverse: true),
            delay: (jiggleIndex * 35).ms,
          )
          .rotate(begin: -0.018, end: 0.018, duration: 140.ms)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
            duration: 140.ms,
          );
    }

    Widget content = IosSpringPressable(
      enabled: !isEditMode,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              iconBody,
              if (showBadge && !isEditMode)
                Positioned(
                  top: -iconSize * 0.04,
                  right: -iconSize * 0.04,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: iconSize * 0.1,
                      vertical: iconSize * 0.04,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(iconSize * 0.2),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: iconSize * 0.14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (isEditMode)
                Positioned(
                  top: -iconSize * 0.08,
                  left: -iconSize * 0.08,
                  child: _RemoveBadge(size: iconSize * 0.28),
                ),
            ],
          ),
          if (showLabel) ...[
            SizedBox(height: metrics.iconLabelGap),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: IosTypography.homeLabel(labelSize),
            ),
          ],
        ],
      ),
    );

    if (enableDrag && isEditMode) {
      content = LongPressDraggable<int>(
        data: jiggleIndex,
        delay: const Duration(milliseconds: 120),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: iconSize,
            child: IosAppIconArt(app: app, size: iconSize),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: content),
        onDragStarted: onDragStarted,
        onDragEnd: (_) => onDragEnded?.call(),
        child: content,
      );
    }

    return content;
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Icon(Icons.remove, color: Colors.white, size: size * 0.62),
    );
  }
}
