import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/soft_ui_primitives.dart';

/// Modal đặt món — đồng bộ design system.
class FoodOrderSheet extends StatelessWidget {
  const FoodOrderSheet({
    super.key,
    required this.name,
    required this.description,
    required this.unitPriceLabel,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  final String name;
  final String description;
  final String unitPriceLabel;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;

  static Future<void> show(
    BuildContext context, {
    required String name,
    required String description,
    required String unitPriceLabel,
    required int initialQty,
    required ValueChanged<int> onQtyChanged,
    required VoidCallback onAddToCart,
  }) {
    var qty = initialQty;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final total = _multiplyPrice(unitPriceLabel, qty);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SoftModernTokens.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SoftModernTokens.radiusSheet),
                  ),
                  boxShadow: SoftModernTokens.sheetShadow,
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      AppSpacing.small,
                      AppSpacing.medium,
                      AppSpacing.medium,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: SoftModernTokens.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: SoftModernTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: SoftModernTokens.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Row(
                          children: [
                            _QtyButton(
                              icon: Icons.remove_rounded,
                              onTap: qty > 1
                                  ? () {
                                      qty--;
                                      onQtyChanged(qty);
                                      setModalState(() {});
                                    }
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '$qty',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: SoftModernTokens.textPrimary,
                                ),
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add_rounded,
                              onTap: () {
                                qty++;
                                onQtyChanged(qty);
                                setModalState(() {});
                              },
                            ),
                            const Spacer(),
                            Text(
                              '$totalđ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: SoftModernTokens.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        SoftPrimaryButton(
                          label: 'Thêm vào giỏ',
                          onPressed: onAddToCart,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _multiplyPrice(String unitLabel, int qty) {
    final digits = unitLabel.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return unitLabel;
    final value = int.parse(digits) * qty;
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _QtyButton extends StatefulWidget {
  const _QtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_QtyButton> createState() => _QtyButtonState();
}

class _QtyButtonState extends State<_QtyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? SoftModernTokens.pressScale : 1.0,
      duration: SoftModernTokens.animationFast,
      child: Material(
        color: SoftModernTokens.surfaceMuted,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              widget.icon,
              size: 22,
              color: widget.onTap != null
                  ? SoftModernTokens.primary
                  : SoftModernTokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
