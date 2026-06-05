import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/navigation/core/route_label_utils.dart';

/// Tuyến đường OSRM — polyline + khoảng cách + thời gian.
class RoutePlan {
  final List<LatLng> points;
  final double distanceKm;
  final int durationSeconds;

  /// Khoảng cách (m) giữa điểm đích yêu cầu và điểm cuối polyline OSRM.
  final double? destinationSnapMeters;

  const RoutePlan({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
    this.destinationSnapMeters,
  });

  DateTime get eta => DateTime.now().add(Duration(seconds: durationSeconds));

  static String etaLabelForDurationSeconds(int durationSeconds) =>
      RouteLabelUtils.formatEtaForDurationSeconds(durationSeconds);

  String get distanceLabel => RouteLabelUtils.formatDistanceKm(distanceKm);

  String get durationLabel =>
      RouteLabelUtils.formatDurationSeconds(durationSeconds);

  String get etaLabel => etaLabelForDurationSeconds(durationSeconds);
}
