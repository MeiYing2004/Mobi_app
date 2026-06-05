/// Lỗi geocoding (Nominatim forward / reverse).
class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);

  @override
  String toString() => message;
}

/// Lỗi routing (OSRM).
class RoutingException implements Exception {
  final String message;
  const RoutingException(this.message);

  @override
  String toString() => message;
}
