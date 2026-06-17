import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';
import 'package:fuel_tracker_app/features/auth/theme/auth_tokens.dart';
import 'package:fuel_tracker_app/features/premium/premium_manager.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_guard.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';

class UsageHistoryScreen extends StatelessWidget {
  const UsageHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    final history = session.tripHistory;

    return Scaffold(
      backgroundColor: AuthTokens.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const AuthDetailHeader(title: 'Trip History'),
            Expanded(
              child: PremiumGuard(
                feature: PremiumFeature.tripHistory,
                title: 'Trip History',
                description: 'Unlock trip history, exports & advanced statistics',
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có lịch sử chuyến đi',
                          style: TextStyle(color: AuthTokens.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: history.length,
                        itemBuilder: (context, i) {
                          final item = history[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AuthTokens.glassFill,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AuthTokens.glassBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AuthTokens.glassHighlight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: AuthTokens.neonBlue,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: AuthTokens.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        style: const TextStyle(
                                          color: AuthTokens.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.detail,
                                  style: const TextStyle(
                                    color: AuthTokens.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (50 * i).ms).slideX(begin: 0.04);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
