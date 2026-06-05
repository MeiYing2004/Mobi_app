import 'package:flutter/foundation.dart';

/// Cấu hình dev khi chạy Flutter Web trên LAN (tránh CORS trên trình duyệt).
///
/// Hai chế độ (chỉ áp dụng [kIsWeb]):
/// 1. **Cùng cổng** — `web_dev_config.yaml` proxy; URL tương đối `/nominatim`, …
/// 2. **Proxy riêng** — `dart run tool/dev_cors_proxy.dart` + `--dart-define=OSM_DEV_PROXY=http://<LAN_IP>:8765`
class LanDevConfig {
  LanDevConfig._();

  /// Base URL proxy dev riêng, ví dụ `http://192.168.1.10:8765`.
  /// Truyền khi chạy: `--dart-define=OSM_DEV_PROXY=http://<LAN_IP>:8765`
  static const String proxyBase = String.fromEnvironment(
    'OSM_DEV_PROXY',
    defaultValue: '',
  );

  /// Web: luôn đi qua prefix proxy (cùng cổng hoặc cổng 8765).
  static bool get useDevProxy => kIsWeb;

  static bool get useExternalProxy => kIsWeb && proxyBase.trim().isNotEmpty;

  static String get normalizedProxyBase {
    final raw = proxyBase.trim();
    if (raw.isEmpty) return raw;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Path or full origin for Web proxy routes.
  static String proxyPath(String prefix) {
    if (!kIsWeb) return prefix;
    if (useExternalProxy) {
      return '$normalizedProxyBase/$prefix';
    }
    return '/$prefix';
  }

  static String apiOrigin(String proxyPrefix, String directOrigin) {
    if (!kIsWeb) return directOrigin;
    return proxyPath(proxyPrefix);
  }
}
