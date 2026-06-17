/// Gói Premium — lưu vào data.json.
enum PremiumPlanType {
  monthly('monthly', 'Hàng tháng', 99000),
  yearly('yearly', 'Hàng năm', 799000),
  lifetime('lifetime', 'Trọn đời', 1999000);

  const PremiumPlanType(this.id, this.label, this.priceVnd);
  final String id;
  final String label;
  final int priceVnd;

  static PremiumPlanType? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  String get priceLabel {
    final s = priceVnd.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  String get periodLabel => switch (this) {
        PremiumPlanType.monthly => '/tháng',
        PremiumPlanType.yearly => '/năm',
        PremiumPlanType.lifetime => 'một lần',
      };

  String? get badge => switch (this) {
        PremiumPlanType.monthly => null,
        PremiumPlanType.yearly => 'Phổ biến nhất • Tiết kiệm 33%',
        PremiumPlanType.lifetime => 'Giá trị tốt nhất',
      };

  /// Ngày hết hạn — lifetime không hết hạn.
  String computeExpireAt(DateTime from) {
    if (this == PremiumPlanType.lifetime) return '';
    final end = switch (this) {
      PremiumPlanType.monthly => DateTime(from.year, from.month + 1, from.day),
      PremiumPlanType.yearly => DateTime(from.year + 1, from.month, from.day),
      PremiumPlanType.lifetime => from,
    };
    return end.toIso8601String().split('T').first;
  }
}
