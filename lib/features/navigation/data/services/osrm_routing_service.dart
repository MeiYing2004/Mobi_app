import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/osm_config.dart';
import 'package:fuel_tracker_app/core/network/osm_http.dart';
import 'package:fuel_tracker_app/features/geocoding/data/exceptions/map_navigation_exceptions.dart';
import 'package:fuel_tracker_app/features/navigation/core/navigation_performance.dart';
import 'package:fuel_tracker_app/features/navigation/data/models/route_plan.dart';
import 'package:fuel_tracker_app/features/navigation/data/services/osrm_route_parser.dart';

/// Tính tuyến đường qua OSRM (Open Source Routing Machine).
class OsrmRoutingService {
  OsrmRoutingService({OsmHttpClient? httpClient})
      : _http = httpClient ?? OsmHttpClient.forOsrm();

  final OsmHttpClient _http;

  Future<RoutePlan>? _inFlightPlan;
  String? _inFlightKey;
  RoutePlan? _cachedPlan;
  String? _cachedPlanKey;
  DateTime? _cachedPlanAt;

  /// `overview=simplified` (navigation); `overview=full` chỉ khi [highPrecision].
  Future<RoutePlan> planRoute({
    required LatLng origin,
    required LatLng destination,
    bool highPrecision = false,
  }) async {
    OsrmRouteParser.validateEndpoints(origin, destination);

    final simplified = !highPrecision;
    final key = _planKey(origin, destination, simplified);

    final cached = _cachedPlan;
    if (cached != null &&
        _cachedPlanKey == key &&
        _cachedPlanAt != null &&
        DateTime.now().difference(_cachedPlanAt!) <
            NavigationPerformance.routePlanDedupeWindow) {
      return cached;
    }

    if (_inFlightPlan != null && _inFlightKey == key) {
      return _inFlightPlan!;
    }

    final overviewLabel = simplified
        ? NavigationPerformance.osrmOverviewNavigation
        : NavigationPerformance.osrmOverviewFull;
    debugPrint(
      '[OSRM] planRoute profile=${OsrmRouteParser.drivingProfile} '
      'overview=$overviewLabel '
      '(${origin.latitude},${origin.longitude}) → '
      '(${destination.latitude},${destination.longitude})',
    );

    final future = _fetchRoute(
      origin: origin,
      destination: destination,
      simplifiedOverview: simplified,
    );
    _inFlightKey = key;
    _inFlightPlan = future;

    try {
      final plan = await future;
      _cachedPlan = plan;
      _cachedPlanKey = key;
      _cachedPlanAt = DateTime.now();
      return plan;
    } on RoutingException catch (e) {
      debugPrint('[OSRM] FAILURE: $e');
      rethrow;
    } finally {
      if (_inFlightKey == key) {
        _inFlightPlan = null;
        _inFlightKey = null;
      }
    }
  }

  Future<RoutePlan> _fetchRoute({
    required LatLng origin,
    required LatLng destination,
    required bool simplifiedOverview,
  }) async {
    final uri = _buildRouteUri(
      origin: origin,
      destination: destination,
      simplifiedOverview: simplifiedOverview,
    );

    debugPrint('[OSRM] REQUEST GET $uri');

    http.Response response;
    try {
      response = await _http.get(uri);
    } on TimeoutException catch (e) {
      debugPrint('[OSRM] FAILURE timeout: $e');
      throw const RoutingException('Hết thời gian kết nối OSRM');
    } on SocketException catch (e) {
      debugPrint('[OSRM] FAILURE socket: $e');
      throw const RoutingException('Không có kết nối mạng để lấy tuyến');
    } on http.ClientException catch (e) {
      debugPrint('[OSRM] FAILURE client: $e');
      throw RoutingException('Lỗi kết nối OSRM: ${e.message}');
    } on FormatException catch (e) {
      debugPrint('[OSRM] FAILURE json: $e');
      throw const RoutingException('Phản hồi OSRM không hợp lệ');
    }

    debugPrint(
      '[OSRM] RESPONSE HTTP ${response.statusCode} '
      'bytes=${response.body.length}',
    );

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}…'
          : response.body;
      debugPrint('[OSRM] FAILURE body=$snippet');
      throw RoutingException('OSRM HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final code = data['code'] as String?;
    if (code != 'Ok') {
      final msg = OsrmRouteParser.messageForOsrmCode(code);
      debugPrint('[OSRM] FAILURE code=$code message=$msg');
      throw RoutingException(msg);
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      debugPrint('[OSRM] FAILURE routes rỗng');
      throw const RoutingException('Không có tuyến đường');
    }

    debugPrint('[OSRM] RESPONSE routes=${routes.length} code=$code');

    final best = OsrmRouteParser.pickBestRoute(routes);
    if (best == null) {
      debugPrint('[OSRM] FAILURE không parse được route hợp lệ');
      throw const RoutingException('Không có tuyến đường hợp lệ');
    }

    return OsrmRouteParser.parseRoutePlan(
      best,
      simplifiedOverview: simplifiedOverview,
      requestedDestination: destination,
    );
  }

  static Uri _buildRouteUri({
    required LatLng origin,
    required LatLng destination,
    required bool simplifiedOverview,
  }) {
    final coords =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final overview = simplifiedOverview
        ? NavigationPerformance.osrmOverviewNavigation
        : NavigationPerformance.osrmOverviewFull;
    return Uri.parse(
      '${OsmConfig.osrmBase}/route/v1/${OsrmRouteParser.drivingProfile}/$coords',
    ).replace(
      queryParameters: {
        'overview': overview,
        'geometries': 'geojson',
        'steps': 'false',
        'alternatives': 'true',
      },
    );
  }

  static String _planKey(LatLng origin, LatLng destination, bool simplified) {
    String c(double v) => v.toStringAsFixed(5);
    return '${c(origin.latitude)},${c(origin.longitude)}→'
        '${c(destination.latitude)},${c(destination.longitude)}|$simplified';
  }
}
