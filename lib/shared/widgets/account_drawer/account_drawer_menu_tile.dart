import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';

class AccountDrawerMenuTile extends StatefulWidget {
  const AccountDrawerMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
    this.selected = false,
    this.animationIndex = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  final bool selected;
  final int animationIndex;

  @override
  State<AccountDrawerMenuTile> createState() => _AccountDrawerMenuTileState();
}

class _AccountDrawerMenuTileState extends State<AccountDrawerMenuTile> {
  bool _hovered = false;
  bool _pressed = false;

  Color get _iconColor {
    if (widget.destructive) return const Color(0xFFFF6B6B);
    if (widget.selected) return LuxuryTokens.neonBlue;
    if (_hovered) return LuxuryTokens.neonCyan;
    return LuxuryTokens.textSecondary;
  }

  Color get _textColor {
    if (widget.destructive) return const Color(0xFFFF6B6B);
    if (widget.selected || _hovered) return LuxuryTokens.textPrimary;
    return LuxuryTokens.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : (_hovered ? 1.01 : 1),
          duration: LuxuryTokens.durationFast,
          curve: LuxuryTokens.curve,
          child: AnimatedContainer(
            duration: LuxuryTokens.duration,
            curve: LuxuryTokens.curve,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.selected
                  ? LuxuryTokens.neonBlue.withValues(alpha: 0.14)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.selected
                    ? LuxuryTokens.neonBlue.withValues(alpha: 0.35)
                    : _hovered
                        ? LuxuryTokens.glassBorderBright
                        : Colors.transparent,
              ),
              boxShadow: widget.selected || _hovered
                  ? LuxuryTokens.elevation(1, glow: LuxuryTokens.neonBlue)
                  : null,
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 22, color: _iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          widget.selected || _hovered ? FontWeight.w600 : FontWeight.w500,
                      color: _textColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (widget.selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxuryTokens.neonCyan,
                      boxShadow: [
                        BoxShadow(
                          color: LuxuryTokens.neonCyan,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return tile
        .animate()
        .fadeIn(delay: (30 * widget.animationIndex).ms, duration: 300.ms)
        .slideX(begin: -0.06, curve: LuxuryTokens.curve);
  }
}
