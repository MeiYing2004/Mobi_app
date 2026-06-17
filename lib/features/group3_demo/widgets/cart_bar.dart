import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';

/// Thanh giỏ hàng nổi — đồng bộ soft modern.
class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.itemCount,
    required this.onClear,
  });

  final int itemCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SoftModernTokens.sheetMarginH,
        0,
        SoftModernTokens.sheetMarginH,
        AppSpacing.small,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SoftModernTokens.surface,
          borderRadius: BorderRadius.circular(SoftModernTokens.radiusSheet),
          boxShadow: SoftModernTokens.cardShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_rounded,
                  color: SoftModernTokens.primary,
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    'Giỏ hàng · $itemCount món',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SoftModernTokens.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text(
                    'Xóa',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: SoftModernTokens.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
