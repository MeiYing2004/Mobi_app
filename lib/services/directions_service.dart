import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/osm_config.dart';

class DirectionsException implements Exception {
  final String message;
  const DirectionsException(this.message);

  @override
  String toString() => message;
}

class DirectionsResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationSeconds;

  const DirectionsResult({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
  });
}

/// Routing qua OSRM (Open Source Routing Machine).
class DirectionsService {
  const DirectionsService();

  static const int _maxAttempts = 2;

  Future<DirectionsResult> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coords =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final uri = Uri.parse(
      '${OsmConfig.osrmBase}/route/v1/driving/$coords'
      '?overview=full&geometries=geojson&steps=false',
    );

    http.Response response;
    try {
      response = await _getWithRetry(uri);
    } on TimeoutException {
      throw const DirectionsException('Hết thời gian kết nối OSRM');
    } on SocketException {
      throw const DirectionsException('Không có kết nối mạng để lấy tuyến');
    } on http.ClientException catch (e) {
      throw DirectionsException('Lỗi kết nối OSRM: ${e.message}');
    } on FormatException {
      throw const DirectionsException('Phản hồi OSRM không hợp lệ');
    }

    if (response.statusCode != 200) {
      throw DirectionsException('OSRM HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw DirectionsException('OSRM: ${data['code']}');
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const DirectionsException('Không có tuyến đường');
    }

    final route = routes.first as Map<String, dynamic>;
    final coordsList =
        (route['geometry'] as Map<String, dynamic>)['coordinates']
            as List<dynamic>;
    final points = coordsList
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    return DirectionsResult(
      points: points,
      distanceKm: (route['distance'] as num) / 1000,
      durationSeconds: (route['duration'] as num).round(),
    );
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await http
            .get(uri, headers: OsmConfig.headers)
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        lastError = e;
        if (attempt == _maxAttempts) rethrow;
      }
    }
    throw lastError ?? const DirectionsException('Lỗi không xác định khi gọi OSRM');
  }
}
