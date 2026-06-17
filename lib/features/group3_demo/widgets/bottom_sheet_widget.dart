import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';

/// Bottom sheet production — margin, shadow, drag handle, draggable.
class BottomSheetWidget extends StatelessWidget {
  const BottomSheetWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.onClose,
    this.scrollController,
    this.footer,
    this.showDragHandle = true,
  });

  final String title;
  final String? subtitle;
  final Widget? child;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
  final Widget? footer;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SoftModernTokens.sheetMarginH,
        0,
        SoftModernTokens.sheetMarginH,
        SoftModernTokens.sheetMarginBottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SoftModernTokens.bottomSheetBackground,
          borderRadius: BorderRadius.circular(SoftModernTokens.radiusSheet),
          boxShadow: SoftModernTokens.sheetShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SoftModernTokens.radiusSheet),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDragHandle) ...[
                  const SizedBox(height: AppSpacing.small),
                  const Icon(
                    Icons.drag_handle_rounded,
                    color: SoftModernTokens.textBody,
                    size: 22,
                  ),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: SoftModernTokens.scrollPhysics,
                    padding: const EdgeInsets.all(SoftModernTokens.sheetPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: SoftModernTokens.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: SoftModernTokens.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (child != null) ...[
                          const SizedBox(height: AppSpacing.medium),
                          child!,
                        ],
                        if (footer != null) ...[
                          const SizedBox(height: AppSpacing.medium),
                          footer!,
                        ],
                        if (onClose != null) ...[
                          const SizedBox(height: AppSpacing.small),
                          TextButton(
                            onPressed: onClose,
                            child: const Text(
                              'Đóng',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: SoftModernTokens.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mở persistent sheet có thể kéo (DraggableScrollableSheet).
  static Future<T?> showDraggable<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? child,
    Widget? footer,
    double initialSize = 0.28,
    double minSize = 0.18,
    double maxSize = 0.55,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          snap: true,
          snapSizes: [minSize, initialSize, maxSize * 0.75],
          builder: (context, scrollController) {
            return BottomSheetWidget(
              title: title,
              subtitle: subtitle,
              scrollController: scrollController,
              footer: footer,
              onClose: () => Navigator.pop(ctx),
              child: child,
            );
          },
        );
      },
    );
  }
}
