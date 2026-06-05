/// Thành phần địa chỉ Việt Nam từ Nominatim `addressdetails`.
class AddressComponents {
  final String? houseNumber;
  final String? street;
  final String? ward;
  final String? district;
  final String? province;
  final String? country;

  const AddressComponents({
    this.houseNumber,
    this.street,
    this.ward,
    this.district,
    this.province,
    this.country,
  });

  factory AddressComponents.fromNominatim(Map<String, dynamic>? address) {
    if (address == null || address.isEmpty) {
      return const AddressComponents();
    }

    String? pick(String key) {
      final v = address[key]?.toString().trim();
      return v == null || v.isEmpty ? null : v;
    }

    final ward = pick('suburb') ??
        pick('neighbourhood') ??
        pick('quarter') ??
        pick('hamlet') ??
        pick('village');

    final district = pick('city_district') ??
        pick('district') ??
        pick('borough') ??
        pick('county');

    final province = pick('state') ??
        pick('city') ??
        pick('town') ??
        pick('province');

    return AddressComponents(
      houseNumber: pick('house_number'),
      street: pick('road') ?? pick('pedestrian') ?? pick('footway'),
      ward: ward,
      district: district,
      province: province,
      country: pick('country'),
    );
  }

  String get shortLabel {
    final parts = <String>[];
    if (street != null) {
      final line = [
        if (houseNumber != null) houseNumber!,
        street!,
      ].join(' ').trim();
      if (line.isNotEmpty) parts.add(line);
    }
    if (ward != null) parts.add(ward!);
    if (district != null) parts.add(district!);
    if (province != null) parts.add(province!);
    return parts.join(', ');
  }

  bool get isEmpty =>
      street == null &&
      ward == null &&
      district == null &&
      province == null &&
      houseNumber == null;
}
