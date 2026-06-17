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
      return _AppErrorFallback(details: details);
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

class _AppErrorFallback extends StatelessWidget {
  const _AppErrorFallback({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final message = kDebugMode
        ? details.exceptionAsString()
        : 'Đã xảy ra lỗi hiển thị.';

    return Material(
      color: const Color(0xFF0D0D12),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra lỗi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: kDebugMode ? 8 : 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ứng dụng vẫn chạy — thử quay lại hoặc khởi động lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
