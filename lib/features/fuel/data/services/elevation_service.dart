import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/osm_config.dart';

class ElevationException implements Exception {
  final String message;
  const ElevationException(this.message);

  @override
  String toString() => message;
}

/// Open-Elevation compatible lookup.
class ElevationService {
  const ElevationService();

  bool get isConfigured => OsmConfig.openElevationLookupUrl.trim().isNotEmpty;

  Future<List<double>> lookupMeters(List<LatLng> points) async {
    if (!isConfigured) return List<double>.filled(points.length, 0);
    if (points.isEmpty) return const [];

    final uri = Uri.parse(OsmConfig.openElevationLookupUrl);
    final body = {
      'locations': points
          .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
          .toList(),
    };

    final res = await http
        .post(
          uri,
          headers: {
            ...OsmConfig.headers,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 18));

    if (res.statusCode != 200) {
      throw ElevationException('Elevation HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? const [];
    final elevations = <double>[];
    for (final raw in results) {
      final m = raw as Map<String, dynamic>;
      elevations.add((m['elevation'] as num?)?.toDouble() ?? 0.0);
    }
    if (elevations.length != points.length) {
      // Keep shape stable; pad/truncate.
      if (elevations.length < points.length) {
        elevations.addAll(
          List<double>.filled(points.length - elevations.length, 0.0),
        );
      } else {
        elevations.removeRange(points.length, elevations.length);
      }
    }
    return elevations;
  }
}

