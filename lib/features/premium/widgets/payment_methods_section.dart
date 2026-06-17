import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';

enum PaymentMethod {
  momo('Momo', Icons.account_balance_wallet_rounded),
  bankTransfer('Thanh toán ngân hàng', Icons.account_balance_rounded);

  const PaymentMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

class PaymentMethodsSection extends StatefulWidget {
  const PaymentMethodsSection({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  State<PaymentMethodsSection> createState() => _PaymentMethodsSectionState();
}

class _PaymentMethodsSectionState extends State<PaymentMethodsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức thanh toán',
          style: TextStyle(
            color: LuxuryTokens.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < PaymentMethod.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _PaymentTile(
                  method: PaymentMethod.values[i],
                  selected: widget.selected == PaymentMethod.values[i],
                  onTap: () => widget.onSelected(PaymentMethod.values[i]),
                )
                    .animate()
                    .fadeIn(delay: (30 * i).ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      curve: Curves.easeOutCubic,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PaymentTile extends StatefulWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PaymentTile> createState() => _PaymentTileState();
}

class _PaymentTileState extends State<_PaymentTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? LuxuryTokens.neonBlue.withValues(alpha: 0.18)
                : LuxuryTokens.surfaceGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected ? LuxuryTokens.neonCyan.withValues(alpha: 0.55) : LuxuryTokens.glassBorder,
              width: widget.selected ? 1.5 : 1,
            ),
            boxShadow: widget.selected ? LuxuryTokens.elevation(2, glow: LuxuryTokens.neonBlue) : null,
          ),
          child: Column(
            children: [
              Icon(
                widget.method.icon,
                color: widget.selected ? LuxuryTokens.neonBlue : LuxuryTokens.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                widget.method.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.selected ? LuxuryTokens.textPrimary : LuxuryTokens.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
