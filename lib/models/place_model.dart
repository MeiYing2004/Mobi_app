import 'package:latlong2/latlong.dart';

/// Gợi ý từ Nominatim (OpenStreetMap).
class PlaceSuggestion {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final List<String> types;
  final LatLng? location;

  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    this.types = const [],
    this.location,
  });
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final LatLng location;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.location,
  });
}
