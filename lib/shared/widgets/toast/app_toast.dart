import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/shared/widgets/toast/toast_tokens.dart';

/// Base glass toast — slide from top, fade, light scale.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onDismiss,
  });

  final ToastType type;
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  IconData get _icon => switch (type) {
        ToastType.success => Icons.check_rounded,
        ToastType.error => Icons.close_rounded,
        ToastType.warning => Icons.warning_amber_rounded,
        ToastType.info => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ToastTokens.maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ToastTokens.horizontalMargin),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ToastTokens.radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: ToastTokens.blur,
                  sigmaY: ToastTokens.blur,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ToastTokens.gradientFor(type),
                    borderRadius: BorderRadius.circular(ToastTokens.radius),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: ToastTokens.shadow(ToastTokens.iconColorFor(type)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ToastTokens.iconColorFor(type),
                          ),
                          child: Icon(_icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title, style: ToastTokens.titleStyle()),
                              if (message.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(message, style: ToastTokens.messageStyle()),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: ToastTokens.duration, curve: ToastTokens.curve)
        .slideY(begin: -0.35, end: 0, duration: ToastTokens.duration, curve: ToastTokens.curve)
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          duration: ToastTokens.duration,
          curve: ToastTokens.curve,
        );
  }
}

class SuccessToast extends StatelessWidget {
  const SuccessToast({
    super.key,
    required this.message,
    this.title = 'Thành công',
    this.onDismiss,
  });

  final String title;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppToast(
      type: ToastType.success,
      title: title,
      message: message,
      onDismiss: onDismiss,
    );
  }
}

class ErrorToast extends StatelessWidget {
  const ErrorToast({
    super.key,
    required this.message,
    this.title = 'Lỗi',
    this.onDismiss,
  });

  final String title;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppToast(
      type: ToastType.error,
      title: title,
      message: message,
      onDismiss: onDismiss,
    );
  }
}

class WarningToast extends StatelessWidget {
  const WarningToast({
    super.key,
    required this.message,
    this.title = 'Cảnh báo',
    this.onDismiss,
  });

  final String title;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppToast(
      type: ToastType.warning,
      title: title,
      message: message,
      onDismiss: onDismiss,
    );
  }
}

class InfoToast extends StatelessWidget {
  const InfoToast({
    super.key,
    required this.message,
    this.title = 'Thông tin',
    this.onDismiss,
  });

  final String title;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppToast(
      type: ToastType.info,
      title: title,
      message: message,
      onDismiss: onDismiss,
    );
  }
}
