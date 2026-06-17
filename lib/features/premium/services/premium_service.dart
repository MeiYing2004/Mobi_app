import 'package:flutter/foundation.dart';

import 'package:fuel_tracker_app/features/auth/services/user_service.dart';
import 'package:fuel_tracker_app/features/premium/models/premium_plan_type.dart';

/// Thanh toán & kích hoạt Premium — ghi data.json qua [UserService].
class PremiumService extends ChangeNotifier {
  PremiumService({UserService? userService})
      : _users = userService;

  final UserService? _users;

  bool processing = false;
  String? lastError;

  Future<bool> activatePlan(PremiumPlanType plan) async {
    final svc = _users;
    if (svc == null || !svc.isLoggedIn) {
      lastError = 'Vui lòng đăng nhập trước';
      return false;
    }

    processing = true;
    lastError = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    final now = DateTime.now();
    final result = await svc.updatePremium(
      premium: true,
      premiumPlan: plan.id,
      premiumExpireAt: plan.computeExpireAt(now),
    );

    processing = false;
    if (!result.success) {
      lastError = result.message ?? svc.lastError;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Demo payment — luôn thành công sau delay.
  Future<bool> processDemoPayment({
    required PremiumPlanType plan,
    required String paymentMethod,
  }) async {
    debugPrint('[PremiumService] demo pay $paymentMethod → ${plan.id}');
    return activatePlan(plan);
  }
}
