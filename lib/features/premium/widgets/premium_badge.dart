import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/features/premium/theme/premium_tokens.dart';

/// Badge FREE (xám) hoặc PREMIUM (vàng phát sáng).
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    required this.isPremium,
    this.compact = false,
  });

  final bool isPremium;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = isPremium ? 'PREMIUM' : 'FREE';
    final bg = isPremium
        ? PremiumTokens.gold.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.06);
    final border = isPremium
        ? PremiumTokens.gold.withValues(alpha: 0.55)
        : LuxuryTokens.glassBorder;
    final fg = isPremium ? PremiumTokens.gold : LuxuryTokens.textMuted;
    final icon = isPremium ? Icons.workspace_premium_rounded : Icons.person_outline_rounded;

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: PremiumTokens.gold.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );

    if (isPremium) {
      badge = badge
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 2200.ms,
            color: Colors.white.withValues(alpha: 0.35),
          );
    }

    return badge;
  }
}
