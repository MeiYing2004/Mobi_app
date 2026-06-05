/// Chuẩn hóa văn bản tiếng Việt cho tìm kiếm địa chỉ (có/không dấu).
class VietnameseTextUtils {
  VietnameseTextUtils._();

  static const _from =
      'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
      'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ';
  static const _to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYYD';

  /// Bỏ dấu tiếng Việt, giữ nguyên khoảng trắng và ký tự khác.
  static String removeDiacritics(String input) {
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      final idx = _from.indexOf(ch);
      buffer.write(idx >= 0 ? _to[idx] : ch);
    }
    return buffer.toString();
  }

  static bool hasDiacritics(String input) =>
      removeDiacritics(input) != input;

  /// Biến thể truy vấn: ưu tiên bản gốc, thêm bản không dấu nếu khác.
  static List<String> searchVariants(String query) {
    final trimmed = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return const [];

    final without = removeDiacritics(trimmed);
    if (without.toLowerCase() == trimmed.toLowerCase()) {
      return [trimmed];
    }
    return [trimmed, without];
  }

  /// Ghép địa chỉ có cấu trúc từ Nominatim addressdetails.
  static String formatStructuredAddress(Map<String, dynamic>? address) {
    if (address == null || address.isEmpty) return '';

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = address[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final parts = <String>[];
    final road = pick(['road', 'pedestrian', 'footway', 'path']);
    final ward = pick(['suburb', 'quarter', 'hamlet', 'neighbourhood', 'village']);
    final district = pick(['city_district', 'district', 'county', 'municipality']);
    final province = pick(['city', 'town', 'state', 'province']);

    if (road != null) parts.add(road);
    if (ward != null && !parts.contains(ward)) parts.add(ward);
    if (district != null && !parts.contains(district)) parts.add(district);
    if (province != null && !parts.contains(province)) parts.add(province);

    return parts.join(', ');
  }
}
