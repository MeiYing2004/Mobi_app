import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/shared/widgets/toast/app_toast.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_tokens.dart';

/// Global toast overlay — top floating, no SnackBar.
abstract final class AppToastService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static BuildContext? get _context => navigatorKey.currentContext;

  static void success({
    String title = 'Thành công',
    required String message,
    Duration? duration,
  }) =>
      _show(
        type: ToastType.success,
        title: title,
        message: message,
        duration: duration,
      );

  static void error({
    String title = 'Lỗi',
    required String message,
    Duration? duration,
  }) =>
      _show(
        type: ToastType.error,
        title: title,
        message: message,
        duration: duration,
      );

  static void warning({
    String title = 'Cảnh báo',
    required String message,
    Duration? duration,
  }) =>
      _show(
        type: ToastType.warning,
        title: title,
        message: message,
        duration: duration,
      );

  static void info({
    String title = 'Thông tin',
    required String message,
    Duration? duration,
  }) =>
      _show(
        type: ToastType.info,
        title: title,
        message: message,
        duration: duration,
      );

  /// Optional context-based show — falls back to [navigatorKey].
  static void show(
    BuildContext? context, {
    required ToastType type,
    required String title,
    required String message,
    Duration? duration,
  }) =>
      _show(
        type: type,
        title: title,
        message: message,
        duration: duration,
        context: context,
      );

  static void _show({
    required ToastType type,
    required String title,
    required String message,
    Duration? duration,
    BuildContext? context,
  }) {
    dismiss();

    final ctx = context ?? _context;
    if (ctx == null) return;

    final overlay = Overlay.of(ctx, rootOverlay: true);
    final top = MediaQuery.paddingOf(ctx).top;

    _entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: top + ToastTokens.topOffset,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: AppToast(
            type: type,
            title: title,
            message: message,
            onDismiss: dismiss,
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    _timer = Timer(duration ?? ToastTokens.durationFor(type), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

/// Backward-compatible facade for existing usages.
abstract final class ToastService {
  static GlobalKey<NavigatorState> get navigatorKey => AppToastService.navigatorKey;

  static void success({
    String title = 'Thành công',
    required String message,
    Duration? duration,
  }) =>
      AppToastService.success(title: title, message: message, duration: duration);

  static void error({
    String title = 'Lỗi',
    required String message,
    Duration? duration,
  }) =>
      AppToastService.error(title: title, message: message, duration: duration);

  static void warning({
    String title = 'Cảnh báo',
    required String message,
    Duration? duration,
  }) =>
      AppToastService.warning(title: title, message: message, duration: duration);

  static void info({
    String title = 'Thông tin',
    required String message,
    Duration? duration,
  }) =>
      AppToastService.info(title: title, message: message, duration: duration);

  static void show(
    BuildContext? context, {
    required ToastType type,
    required String title,
    required String message,
    Duration? duration,
  }) => AppToastService.show(
        context,
        type: type,
        title: title,
        message: message,
        duration: duration,
      );

  static void dismiss() => AppToastService.dismiss();
}
