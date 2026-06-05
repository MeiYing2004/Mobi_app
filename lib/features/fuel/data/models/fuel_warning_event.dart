/// Sự kiện cảnh báo nhiên liệu thấp — dùng cho SnackBar, Dialog, Notification.
class FuelWarningEvent {
  final String title;
  final String message;
  final double fuelPercent;
  final double remainingDistanceKm;

  const FuelWarningEvent({
    required this.title,
    required this.message,
    required this.fuelPercent,
    required this.remainingDistanceKm,
  });
}
