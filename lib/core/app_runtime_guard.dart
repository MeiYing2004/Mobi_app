import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized runtime guard for uncaught app errors.
class AppRuntimeGuard {
  AppRuntimeGuard._();

  static Future<void> run(Future<void> Function() appMain) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _log('FlutterError', details.exception, details.stack);
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      _log('ErrorWidget', details.exception, details.stack);
      return const ColoredBox(
        color: Color(0xFF101014),
        child: Center(
          child: Text(
            'Đã xảy ra lỗi hiển thị. Vui lòng khởi động lại ứng dụng.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _log('PlatformDispatcher', error, stack);
      return true;
    };

    await runZonedGuarded(
      appMain,
      (error, stack) => _log('runZonedGuarded', error, stack),
    );
  }

  static void _log(String source, Object error, StackTrace? stack) {
    debugPrint('[$source] $error');
    if (stack != null) {
      debugPrint(stack.toString());
    }
  }
}
