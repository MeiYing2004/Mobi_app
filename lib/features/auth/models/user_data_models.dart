/// Dữ liệu nhiên liệu riêng từng user — lưu trong data.json.
class UserFuelData {
  const UserFuelData({
    required this.currentFuel,
    required this.tankCapacity,
    required this.avgConsumption,
  });

  final double currentFuel;
  final double tankCapacity;
  final double avgConsumption;

  factory UserFuelData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserFuelData.defaults;
    return UserFuelData(
      currentFuel: (json['currentFuel'] as num?)?.toDouble() ?? 12.0,
      tankCapacity: (json['tankCapacity'] as num?)?.toDouble() ?? 45.0,
      avgConsumption: (json['avgConsumption'] as num?)?.toDouble() ?? 4.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentFuel': currentFuel,
        'tankCapacity': tankCapacity,
        'avgConsumption': avgConsumption,
      };

  static const defaults = UserFuelData(
    currentFuel: 12.0,
    tankCapacity: 45.0,
    avgConsumption: 4.5,
  );

  UserFuelData copyWith({
    double? currentFuel,
    double? tankCapacity,
    double? avgConsumption,
  }) {
    return UserFuelData(
      currentFuel: currentFuel ?? this.currentFuel,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      avgConsumption: avgConsumption ?? this.avgConsumption,
    );
  }
}

/// Một mục lịch sử chuyến đi — riêng từng user.
class TripHistoryEntry {
  const TripHistoryEntry({
    required this.title,
    required this.subtitle,
    required this.detail,
    this.date = '',
  });

  final String title;
  final String subtitle;
  final String detail;
  final String date;

  factory TripHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TripHistoryEntry(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'detail': detail,
        'date': date,
      };
}
