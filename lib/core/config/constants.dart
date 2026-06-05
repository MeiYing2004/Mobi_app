import 'package:latlong2/latlong.dart';

/// Hằng số dùng chung trong app.
class AppConstants {
  AppConstants._();

  /// Hồ sơ xe mặc định dùng cho demo nếu chưa kết nối cảm biến thật.
  static const String defaultVehicleName = 'Kawasaki Ninja 400';
  static const double defaultTankCapacityLiters = 14;
  static const double defaultBaseLPer100Km = 4.0;
  static const double defaultCriticalReserveLiters = 2.0;

  /// Vị trí mặc định khi chưa có GPS (Hà Nội, Việt Nam).
  static const LatLng defaultVietnamLocation = LatLng(21.0285, 105.8542);

  /// Mức zoom bản đồ khi theo dõi vị trí.
  static const double mapZoom = 16;

  /// Ngưỡng cảnh báo nhiên liệu (%).
  static const double fuelWarningPercent = 10;

  /// Ngưỡng cảnh báo quãng đường (km).
  static const double fuelWarningDistanceKm = 20;

  /// Trạm xăng phải nằm trong hành lang này (km) so với tuyến.
  static const double routeStationCorridorKm = 2.5;

  /// Debounce Nominatim khi gõ tìm kiếm (ms).
  static const int searchDebounceMs = 500;

  /// TTL cache kết quả geocoding Nominatim.
  static const Duration geocodingCacheTtl = Duration(minutes: 10);

  /// Số entry tối đa trong cache geocoding.
  static const int geocodingCacheMaxEntries = 128;

  /// Chiều cao tối đa popup gợi ý (px).
  static const double searchSuggestionsMaxHeight = 280;

  /// Số gợi ý tối đa mỗi lần gọi Nominatim.
  static const int searchSuggestionLimit = 8;

  /// Số trạm tối đa hiển thị phía trước trên tuyến (navigation).
  static const int maxAheadStationsOnRoute = 10;

  /// Cho phép hiện trạm vừa đi qua (km) khi lọc phía trước.
  static const double aheadStationLookBackKm = 0.15;

  /// Nguồn tác giả chính thức của ứng dụng.
  static const String authorCredit = 'Tác giả: Lữ Minh Hoàng';
}
