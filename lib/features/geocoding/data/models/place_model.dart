import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/geocoding/data/models/address_components.dart';

/// Gợi ý địa điểm từ Nominatim forward geocoding.
class PlaceSuggestion {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final List<String> types;
  final LatLng? location;
  final AddressComponents? address;

  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    this.types = const [],
    this.location,
    this.address,
  });
}

/// Địa điểm đầy đủ — dùng cho zoom bản đồ và chỉ đường OSRM.
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final LatLng location;
  final AddressComponents? address;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.location,
    this.address,
  });
}
