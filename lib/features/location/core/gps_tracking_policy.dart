/// Ngưỡng GPS / off-route cho navigation (mét).
class GpsTrackingPolicy {
  GpsTrackingPolicy._();

  /// < 30m: coi như trên tuyến — chỉ cập nhật progress.
  static const double onRouteMaxM = 30;

  /// 30–100m: lệch tuyến — progress only, chưa reroute.
  static const double softOffRouteMaxM = 100;

  /// 100–300m: kích hoạt reroute (có cooldown).
  static const double rerouteTriggerM = 100;

  /// ≥ 300m: reroute ngay.
  static const double rerouteImmediateM = 300;

  /// Chỉ dùng fix khi accuracy ≤ giá trị này (m).
  static const double maxAccuracyM = 30;

  /// Đứng yên: tốc độ GPS phải > 0.5 m/s hoặc di chuyển ≥ minMoveM.
  static const double minSpeedMps = 0.5;
  static const double minMoveWhenSlowM = 4;

  /// Cooldown giữa hai lần reroute “mềm” (100–300m), sau khoảng tối thiểu 3s.
  static const Duration rerouteCooldown = Duration(seconds: 28);

  /// Session navigation lưu tối đa (giờ).
  static const Duration sessionMaxAge = Duration(hours: 12);
}
