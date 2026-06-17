import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';

/// Card sản phẩm — fade + scale khi load, press scale khi click.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.priceLabel,
    this.icon = Icons.restaurant_rounded,
    this.onTap,
    this.animationIndex = 0,
  });

  final String name;
  final String priceLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final int animationIndex;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _fade;
  late final Animation<double> _scaleEnter;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: SoftModernTokens.animationSlow,
    );
    _fade = CurvedAnimation(
      parent: _enterController,
      curve: SoftModernTokens.curveOut,
    );
    _scaleEnter = Tween<double>(
      begin: SoftModernTokens.enterScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: SoftModernTokens.curveOut,
    ));

    Future<void>.delayed(
      Duration(milliseconds: widget.animationIndex * 60),
      () {
        if (mounted) _enterController.forward();
      },
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _scaleEnter,
        builder: (context, child) {
          final scale =
              _pressed ? SoftModernTokens.pressScale : _scaleEnter.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SoftModernTokens.surface,
            borderRadius: BorderRadius.circular(SoftModernTokens.radiusCard),
            boxShadow: SoftModernTokens.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(SoftModernTokens.radiusCard),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(SoftModernTokens.radiusCard),
              splashColor: SoftModernTokens.primary.withValues(alpha: 0.08),
              highlightColor: SoftModernTokens.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, size: 28, color: SoftModernTokens.primary),
                    const Spacer(),
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: SoftModernTokens.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.priceLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SoftModernTokens.primary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
