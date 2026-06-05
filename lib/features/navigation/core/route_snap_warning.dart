/// Cảnh báo khi điểm người chọn xa điểm snap OSRM trên mạng đường.
class RouteSnapWarning {
  RouteSnapWarning._();

  static const double ignoreBelowM = 50;
  static const double mildMaxM = 200;

  /// `null` nếu &lt; 50m (không hiển thị).
  static String? messageForSnapMeters(double meters) {
    if (meters < ignoreBelowM) return null;
    final m = meters.round();
    if (meters <= mildMaxM) {
      return 'Điểm chọn cách đường gần nhất ${m}m — '
          'tuyến tính từ vị trí gần lộ giao thông nhất.';
    }
    return 'Điểm được chọn cách đường gần nhất ${m}m. '
        'Tuyến đường được tính từ vị trí gần nhất có thể lưu thông.';
  }

  static bool isStrongWarning(double meters) => meters > mildMaxM;
}
