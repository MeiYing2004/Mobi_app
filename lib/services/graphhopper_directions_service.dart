import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/osm_config.dart';

class GraphHopperException implements Exception {
  final String message;
  const GraphHopperException(this.message);

  @override
  String toString() => message;
}

class GraphHopperRouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationSeconds;

  const GraphHopperRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
  });
}

/// Routing via GraphHopper.
///
/// Notes:
/// - Requires you to provide `OsmConfig.graphHopperBase` in code/config.
/// - If GraphHopper isn't configured, callers should fall back to OSRM.
class GraphHopperDirectionsService {
  const GraphHopperDirectionsService();

  bool get isConfigured => OsmConfig.graphHopperBase.trim().isNotEmpty;

  Future<GraphHopperRouteResult> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (!isConfigured) {
      throw const GraphHopperException('GraphHopper chưa được cấu hình');
    }

    final uri = Uri.parse('${OsmConfig.graphHopperBase}/route').replace(
      queryParameters: <String, String>{
        'point': '${origin.latitude},${origin.longitude}',
        'point.1': '${destination.latitude},${destination.longitude}',
        'profile': 'car',
        'points_encoded': 'false',
        'instructions': 'false',
        if (OsmConfig.graphHopperApiKey.trim().isNotEmpty)
          'key': OsmConfig.graphHopperApiKey,
      },
    );

    final response = await http
        .get(uri, headers: OsmConfig.headers)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw GraphHopperException('GraphHopper HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final paths = data['paths'] as List<dynamic>?;
    if (paths == null || paths.isEmpty) {
      throw const GraphHopperException('GraphHopper: không có tuyến');
    }

    final path = paths.first as Map<String, dynamic>;
    final distanceMeters = (path['distance'] as num?)?.toDouble() ?? 0;
    final timeMs = (path['time'] as num?)?.toInt() ?? 0;
    final pointsObj = path['points'] as Map<String, dynamic>?;
    final coords = (pointsObj?['coordinates'] as List<dynamic>?) ?? const [];
    final points = coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    return GraphHopperRouteResult(
      points: points,
      distanceKm: distanceMeters / 1000.0,
      durationSeconds: (timeMs / 1000).round(),
    );
  }
}

