/// Hằng số tối ưu pipeline navigation (không đổi ngưỡng nghiệp vụ off-route).
class NavigationPerformance {
  NavigationPerformance._();

  /// Polyline tối đa trước khi decimate cho render / off-route corridor.
  static const int maxPolylinePoints = 2000;

  /// OSRM overview mặc định khi navigation.
  static const String osrmOverviewNavigation = 'simplified';

  /// OSRM overview khi debug / kiểm tra độ chính xác polyline.
  static const String osrmOverviewFull = 'full';

  /// Dedupe planRoute cùng cặp điểm trong cửa sổ này.
  static const Duration routePlanDedupeWindow = Duration(seconds: 8);

  /// GPS off-route check tối thiểu (tránh mỗi tick).
  static const Duration navigationGpsCheckInterval = Duration(seconds: 2);

  /// Tối thiểu giữa hai lần gọi OSRM reroute.
  static const Duration rerouteMinInterval = Duration(seconds: 3);

  /// Sau lifecycle resume — không reroute trong khoảng này.
  static const Duration lifecycleRerouteGrace = Duration(seconds: 4);

  /// Tải lại cây xăng quanh user tối thiểu.
  static const Duration gasStationsReloadInterval = Duration(minutes: 2);

  /// Di chuyển tối thiểu (m) trước khi refresh gas quanh user.
  static const double gasStationsMinMoveM = 600;
}
