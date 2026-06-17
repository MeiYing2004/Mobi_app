import 'package:fuel_tracker_app/features/auth/models/user_model.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';

/// Tính năng cần Premium — dùng cho [PremiumGuard].
enum PremiumFeature {
  fuelAnalytics,
  fuelPrediction,
  fuelOptimization,
  currentFuelAnalysis,
  remainingRange,
  fuelStationSuggestions,
  fuelCostEstimation,
  routeEfficiency,
  tripHistory,
  exportPdf,
  exportExcel,
  advancedStatistics,
  aiAssistant,
  multiDeviceSync,
}

/// Phân quyền FREE vs PREMIUM — không hardcode trong UI.
abstract final class PremiumManager {
  static bool isPremiumActive(UserSessionService session) => session.isPremiumActive;

  static bool canAccess(UserSessionService session, PremiumFeature feature) {
    return isPremiumActive(session);
  }

  static bool canAccessUser(UserModel? user, PremiumFeature feature) {
    if (user == null || !user.premium) return false;
    if (user.premiumExpireAt.isEmpty) return true;
    final parsed = DateTime.tryParse(user.premiumExpireAt);
    if (parsed == null) return true;
    return !DateTime.now().isAfter(parsed);
  }

  /// FREE: map + route + distance + ETA + time.
  static bool isFreeMapFeature(PremiumFeature feature) => false;

  static String featureTitle(PremiumFeature feature) => switch (feature) {
        PremiumFeature.fuelAnalytics => 'Phân tích nhiên liệu',
        PremiumFeature.fuelPrediction => 'Dự đoán nhiên liệu AI',
        PremiumFeature.fuelOptimization => 'Tối ưu nhiên liệu',
        PremiumFeature.currentFuelAnalysis => 'Nhiên liệu hiện tại',
        PremiumFeature.remainingRange => 'Quãng đường còn lại',
        PremiumFeature.fuelStationSuggestions => 'Gợi ý trạm nhiên liệu',
        PremiumFeature.fuelCostEstimation => 'Ước tính chi phí nhiên liệu',
        PremiumFeature.routeEfficiency => 'Hiệu quả lộ trình',
        PremiumFeature.tripHistory => 'Lịch sử chuyến đi',
        PremiumFeature.exportPdf => 'PDF Export',
        PremiumFeature.exportExcel => 'Excel Export',
        PremiumFeature.advancedStatistics => 'Thống kê nâng cao',
        PremiumFeature.aiAssistant => 'Trợ lý AI',
        PremiumFeature.multiDeviceSync => 'Đồng bộ đám mây',
      };
}
