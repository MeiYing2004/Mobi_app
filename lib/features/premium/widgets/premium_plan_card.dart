import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/features/premium/theme/premium_tokens.dart';

class PremiumPlanCard extends StatefulWidget {
  const PremiumPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
    this.recommended = false,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool recommended;

  @override
  State<PremiumPlanCard> createState() => _PremiumPlanCardState();
}

class _PremiumPlanCardState extends State<PremiumPlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final glow = active || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.03 : (active ? 1.01 : 1.0),
          duration: LuxuryTokens.duration,
          curve: LuxuryTokens.curve,
          child: AnimatedContainer(
            duration: LuxuryTokens.duration,
            curve: LuxuryTokens.curve,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: active || widget.recommended
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        LuxuryTokens.neonBlue.withValues(alpha: 0.28),
                        LuxuryTokens.backgroundElevated.withValues(alpha: 0.9),
                      ],
                    )
                  : null,
              color: active || widget.recommended ? null : LuxuryTokens.surfaceGlass,
              borderRadius: BorderRadius.circular(LuxuryTokens.radiusLg),
              border: Border.all(
                color: glow ? LuxuryTokens.neonCyan.withValues(alpha: 0.6) : LuxuryTokens.glassBorder,
                width: active ? 2 : 1,
              ),
              boxShadow: glow ? LuxuryTokens.elevation(3, glow: LuxuryTokens.neonBlue) : LuxuryTokens.elevation(1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LuxuryTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (widget.badge != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 170),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.recommended
                                ? LuxuryTokens.neonBlue.withValues(alpha: 0.25)
                                : LuxuryTokens.gold.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(PremiumTokens.radiusBadge),
                            border: Border.all(
                              color: widget.recommended
                                  ? LuxuryTokens.neonCyan.withValues(alpha: 0.5)
                                  : LuxuryTokens.gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            widget.badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.recommended
                                  ? LuxuryTokens.neonCyan
                                  : LuxuryTokens.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.price,
                      style: const TextStyle(
                        color: LuxuryTokens.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        widget.period,
                        style: const TextStyle(
                          color: LuxuryTokens.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: LuxuryTokens.curve)
        .slideY(begin: 0.08, curve: LuxuryTokens.curve);
  }
}

class PremiumBenefitList extends StatelessWidget {
  const PremiumBenefitList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quyền lợi Premium',
          style: TextStyle(
            color: LuxuryTokens.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < PremiumTokens.benefits.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: LuxuryTokens.neonBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LuxuryTokens.neonCyan.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: LuxuryTokens.neonCyan,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    PremiumTokens.benefits[i],
                    style: const TextStyle(
                      color: LuxuryTokens.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: (35 * i).ms).slideX(begin: 0.04),
          ),
      ],
    );
  }
}
