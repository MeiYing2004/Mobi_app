import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/geocoding/data/models/place_model.dart';
import 'package:fuel_tracker_app/features/navigation/data/models/route_plan.dart';
import 'package:fuel_tracker_app/features/geocoding/data/services/nominatim_geocoding_service.dart';
import 'package:fuel_tracker_app/features/navigation/data/services/osrm_routing_service.dart';

/// Facade tìm kiếm địa chỉ + chỉ đường (Nominatim + OSRM).
class MapNavigationRepository {
  MapNavigationRepository({
    NominatimGeocodingService? geocoding,
    OsrmRoutingService? routing,
  })  : geocoding = geocoding ?? NominatimGeocodingService(),
        routing = routing ?? OsrmRoutingService();

  final NominatimGeocodingService geocoding;
  final OsrmRoutingService routing;

  Future<List<PlaceSuggestion>> searchPlaces({
    required String query,
    LatLng? bias,
  }) =>
      geocoding.search(query: query, bias: bias);

  Future<PlaceDetails> resolvePlace(PlaceSuggestion suggestion) =>
      geocoding.resolveForNavigation(suggestion);

  Future<PlaceDetails> resolveFromQuery({
    required String query,
    LatLng? bias,
  }) =>
      geocoding.resolveFromQuery(query: query, bias: bias);

  Future<PlaceDetails> reverseGeocode(LatLng location) =>
      geocoding.reverse(location: location);

  Future<RoutePlan> planRoute({
    required LatLng origin,
    required LatLng destination,
  }) =>
      routing.planRoute(origin: origin, destination: destination);
}
