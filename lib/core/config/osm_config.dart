import 'package:fuel_tracker_app/core/config/lan_dev_config.dart';

/// Cấu hình OpenStreetMap — không cần API key.
class OsmConfig {
  OsmConfig._();

  static const String appName = 'FuelTrackerApp';
  static const String appVersion = '2.0.0';
  static const String contactEmail = 'fuel-tracker@mobiapp.local';
  static const String appWebsite = 'https://github.com/mobiapp/fuel-tracker';

  /// User-Agent theo chính sách Nominatim: tên app + phiên bản + liên hệ.
  /// https://operations.osmfoundation.org/policies/nominatim/
  static const String userAgent =
      '$appName/$appVersion (+$appWebsite; $contactEmail)';

  static const String _nominatimDirect = 'https://nominatim.openstreetmap.org';
  static const String _osrmDirect = 'https://router.project-osrm.org';

  static const List<String> _overpassDirect = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass-api.de/api/interpreter',
  ];

  static const List<String> _overpassProxyKeys = [
    'overpass/kumi',
    'overpass/lz4',
    'overpass/de',
  ];

  static String get nominatimBase =>
      LanDevConfig.apiOrigin('nominatim', _nominatimDirect);

  static String get overpassEndpoint => overpassEndpoints.last;

  static List<String> get overpassEndpoints {
    if (!LanDevConfig.useDevProxy) return _overpassDirect;
    return _overpassProxyKeys
        .map((key) => LanDevConfig.apiOrigin(key, ''))
        .toList(growable: false);
  }

  static String get osrmBase => LanDevConfig.apiOrigin('osrm', _osrmDirect);

  static const String openElevationLookupUrl = '';

  static const String _darkTileDirect =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static String get darkTileUrl => tileUrl(
        direct: _darkTileDirect,
        proxyPath: 'carto/dark_all/{z}/{x}/{y}{r}.png',
      );

  static const String tileAttribution = '© OpenStreetMap © CARTO';

  /// URL tile: khi Web + proxy LAN bỏ subdomain `{s}`.
  static String tileUrl({
    required String direct,
    required String proxyPath,
  }) {
    if (!LanDevConfig.useDevProxy) return direct;
    return LanDevConfig.proxyPath(proxyPath);
  }

  /// Header chung (OSRM, Overpass, …).
  static Map<String, String> get headers => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      };

  /// Header bắt buộc cho mọi request Nominatim.
  static Map<String, String> get nominatimHeaders => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
        'Accept-Language': 'vi',
      };
}
