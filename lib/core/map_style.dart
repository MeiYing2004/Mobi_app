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
  static const String cartoDarkMatter =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const String cartoDarkAttribution = '© OpenStreetMap © CARTO';

  /// Giao diện sáng Carto Voyager.
  static const String cartoVoyager =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  static const String cartoVoyagerAttribution = '© OpenStreetMap © CARTO';

  /// Vệ tinh — Esri dùng thứ tự z/y/x trong URL.
  static const String esriWorldImagery =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  static const String esriAttribution = '© Esri © OpenStreetMap contributors';

  static const String openTopoMap =
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';

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
