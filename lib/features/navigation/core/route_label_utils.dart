/// Định dạng nhãn khoảng cách / thời gian / ETA cho tuyến OSRM.
class RouteLabelUtils {
  const RouteLabelUtils._();

  static String formatDistanceKm(double distanceKm) {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static String formatDurationSeconds(int durationSeconds) {
    final m = (durationSeconds / 60).round();
    if (m < 60) return '$m phút';
    final h = m ~/ 60;
    final rm = m % 60;
    return rm == 0 ? '$h giờ' : '$h giờ $rm phút';
  }

  static String formatEtaForDurationSeconds(int durationSeconds) {
    final eta = DateTime.now().add(Duration(seconds: durationSeconds));
    final h = eta.hour.toString().padLeft(2, '0');
    final min = eta.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}
