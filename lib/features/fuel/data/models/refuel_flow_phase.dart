/// Luồng xử lý khi không đủ nhiên liệu trong chỉ đường.
enum RefuelFlowPhase {
  /// Chưa ghé trạm — hiển thị cảnh báo và nút tới trạm gần nhất.
  needRefuel,

  /// Đang dẫn đường tới trạm xăng đã chọn.
  goToGasStation,

  /// Đã tới trạm — chờ người dùng tiếp tục hành trình.
  /// (REFUEL_STATION_ROUTE khi đang dẫn tới trạm: [goToGasStation])
  arrivedGasStation,

  /// Đã đổ/nạp xăng — sẵn sàng tiếp tục tới đích ban đầu.
  readyToContinueTrip,

  /// Đang khôi phục tuyến tới đích ban đầu (chuyển tiếp ngắn).
  continueTrip,
}

extension RefuelFlowPhaseX on RefuelFlowPhase {
  /// Đang trên tuyến tới trạm xăng (REFUEL_STATION_ROUTE).
  bool get isRefuelStationRoute => this == RefuelFlowPhase.goToGasStation;

  bool get showsRefuelDebugDemoButton =>
      isRefuelStationRoute || this == RefuelFlowPhase.arrivedGasStation;

  bool get isDetourActive =>
      isRefuelStationRoute ||
      this == RefuelFlowPhase.arrivedGasStation ||
      this == RefuelFlowPhase.readyToContinueTrip ||
      this == RefuelFlowPhase.continueTrip;
}
