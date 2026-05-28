import 'package:latlong2/latlong.dart';

/// Trạm xăng từ Overpass API.
class GasStation {
  final String id;
  final String osmType;
  final int osmId;
  final String name;
  final String address;
  final LatLng location;
  final double distanceKm;
  final String brand;
  final String? operatorName;
  final String? openingHours;
  final String? phone;
  final String? website;
  final List<String> fuelTypes;
  final List<String> services;
  final Map<String, String> tags;

  const GasStation({
    required this.id,
    required this.osmType,
    required this.osmId,
    required this.name,
    required this.address,
    required this.location,
    required this.distanceKm,
    this.brand = 'Fuel',
    this.operatorName,
    this.openingHours,
    this.phone,
    this.website,
    this.fuelTypes = const [],
    this.services = const [],
    this.tags = const {},
  });

  String get openingHoursLabel => openingHours ?? 'Không rõ giờ mở cửa';
}
