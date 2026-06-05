import 'package:fuel_tracker_app/core/config/osm_config.dart';

/// Kiểu bản đồ OpenStreetMap.
enum MapVisualStyle {
  /// Bản đồ tối — đường phát sáng xanh (Carto Dark Matter).
  dark,

  /// Đường phố (Carto Voyager, dữ liệu OSM).
  standard,

  /// Ảnh vệ tinh (Esri World Imagery).
  satellite,

  /// Địa hình (OpenTopoMap, OSM).
  terrain,
}

/// URL tile + ghi chú bản quyền.
class OsmMapTiles {
  OsmMapTiles._();

  /// Bản đồ tối — phù hợp UI xe ban đêm.
  static const String _cartoDarkDirect =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static String get cartoDarkMatter => OsmConfig.tileUrl(
        direct: _cartoDarkDirect,
        proxyPath: 'carto/dark_all/{z}/{x}/{y}{r}.png',
      );

  static const String cartoDarkAttribution = '© OpenStreetMap © CARTO';

  /// Giao diện sáng Carto Voyager.
  static const String _cartoVoyagerDirect =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  static String get cartoVoyager => OsmConfig.tileUrl(
        direct: _cartoVoyagerDirect,
        proxyPath: 'carto/voyager/{z}/{x}/{y}{r}.png',
      );

  static const String cartoVoyagerAttribution = '© OpenStreetMap © CARTO';

  /// Vệ tinh — Esri dùng thứ tự z/y/x trong URL.
  static const String _esriDirect =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  static String get esriWorldImagery => OsmConfig.tileUrl(
        direct: _esriDirect,
        proxyPath: 'esri/world/{z}/{y}/{x}',
      );

  static const String esriAttribution = '© Esri © OpenStreetMap contributors';

  static const String _openTopoDirect =
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';

  static String get openTopoMap => OsmConfig.tileUrl(
        direct: _openTopoDirect,
        proxyPath: 'opentopo/{z}/{x}/{y}.png',
      );

  static const String openTopoAttribution =
      '© OpenStreetMap © OpenTopoMap (CC-BY-SA)';

  static String attributionFor(MapVisualStyle style) {
    switch (style) {
      case MapVisualStyle.dark:
        return cartoDarkAttribution;
      case MapVisualStyle.standard:
        return cartoVoyagerAttribution;
      case MapVisualStyle.satellite:
        return esriAttribution;
      case MapVisualStyle.terrain:
        return openTopoAttribution;
    }
  }
}
