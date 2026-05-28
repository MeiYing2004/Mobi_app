import 'package:latlong2/latlong.dart';

/// Điểm trên polyline cách điểm đầu [distanceKm] km.
LatLng? pointAlongPolylineAtKm(List<LatLng> points, double distanceKm) {
  if (points.length < 2 || distanceKm <= 0) return points.first;

  const distance = Distance();
  var traveled = 0.0;

  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final segKm = distance.as(LengthUnit.Kilometer, a, b);
    if (segKm <= 0) continue;

    if (traveled + segKm >= distanceKm) {
      final t = (distanceKm - traveled) / segKm;
      return LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
    }
    traveled += segKm;
  }

  return points.last;
}

double polylineLengthKm(List<LatLng> points) {
  if (points.length < 2) return 0;
  const distance = Distance();
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += distance.as(LengthUnit.Kilometer, points[i - 1], points[i]);
  }
  return total;
}
