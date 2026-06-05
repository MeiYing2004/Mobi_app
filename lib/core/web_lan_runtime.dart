import 'package:flutter/foundation.dart';

/// Runtime LAN info injected by `scripts/run_web_lan.*` via `--dart-define`.
class WebLanRuntime {
  WebLanRuntime._();

  static const String lanHost = String.fromEnvironment(
    'WEB_LAN_HOST',
    defaultValue: '',
  );

  static const String lanPort = String.fromEnvironment(
    'WEB_LAN_PORT',
    defaultValue: '',
  );

  static const String corsMode = String.fromEnvironment(
    'WEB_CORS_MODE',
    defaultValue: 'builtin',
  );

  static bool get hasInfo =>
      kIsWeb && lanHost.trim().isNotEmpty && lanPort.trim().isNotEmpty;

  static int? get port => int.tryParse(lanPort.trim());

  static String get localUrl => hasInfo ? 'http://127.0.0.1:$lanPort' : '';

  static String get lanUrl => hasInfo ? 'http://$lanHost:$lanPort' : '';

  static String get corsLabel => corsMode == 'external'
      ? 'External proxy (OSM_DEV_PROXY)'
      : 'Built-in (web_dev_config.yaml)';

  /// Logs once at startup (debug Web only).
  static void logStartup() {
    if (!kDebugMode || !hasInfo) return;
    debugPrint('');
    debugPrint('========== Web LAN debug ==========');
    debugPrint('Local URL : $localUrl');
    debugPrint('LAN URL   : $lanUrl  <- open on phone');
    debugPrint('Port      : $lanPort');
    debugPrint('CORS      : $corsLabel');
    debugPrint('===================================');
    debugPrint('');
  }
}
