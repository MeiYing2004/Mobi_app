import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';

/// Menu item drawer — AnimatedContainer, ripple, scale mượt.
class DrawerItem extends StatefulWidget {
  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<DrawerItem> {
  bool _hovered = false;
  bool _pressed = false;
  double _scale = 1.0;

  @override
  void didUpdateWidget(DrawerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _playSelectAnimation();
    }
  }

  Future<void> _playSelectAnimation() async {
    setState(() => _scale = SoftModernTokens.pressScale);
    await Future<void>.delayed(SoftModernTokens.animationDuration);
    if (mounted) setState(() => _scale = 1.0);
  }

  Color get _backgroundColor {
    if (widget.selected) return SoftModernTokens.itemSelected;
    if (_hovered) return SoftModernTokens.itemHover;
    return Colors.transparent;
  }

  Color get _textColor =>
      widget.selected ? SoftModernTokens.primary : SoftModernTokens.textBody;

  Color get _iconColor =>
      widget.selected ? SoftModernTokens.primary : SoftModernTokens.iconDefault;

  Future<void> _handleTap() async {
    setState(() => _pressed = true);
    await Future<void>.delayed(SoftModernTokens.tapDelay);
    if (!mounted) return;
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? SoftModernTokens.pressScale : _scale;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: SoftModernTokens.animationDuration,
        curve: SoftModernTokens.curveOut,
        child: AnimatedContainer(
          duration: SoftModernTokens.animationDuration,
          curve: SoftModernTokens.curveOut,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(SoftModernTokens.radiusItem),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(SoftModernTokens.radiusItem),
              splashColor: SoftModernTokens.primary.withValues(alpha: 0.12),
              highlightColor: SoftModernTokens.primary.withValues(alpha: 0.06),
              hoverColor: SoftModernTokens.itemHover,
              child: SizedBox(
                height: SoftModernTokens.itemHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SoftModernTokens.itemHorizontalPadding,
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 24, color: _iconColor),
                      const SizedBox(width: SoftModernTokens.itemHorizontalPadding),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: SoftModernTokens.animationDuration,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                widget.selected ? FontWeight.w600 : FontWeight.w500,
                            color: _textColor,
                            height: 1.25,
                          ),
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
