import 'package:flutter/material.dart';

import '../core/micro_motion_spec.dart';
import '../core/vehicle_ui_tokens.dart';

class QuickActionChipData {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const QuickActionChipData({
    required this.label,
    required this.icon,
    this.onTap,
  });
}

/// Compact category chips below search.
class QuickActionChips extends StatelessWidget {
  final List<QuickActionChipData> items;

  const QuickActionChips({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return _ChipButton(
            label: item.label,
            icon: item.icon,
            onTap: item.onTap,
            brightness: b,
          );
        },
      ),
    );
  }
}

class _ChipButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Brightness brightness;

  const _ChipButton({
    required this.label,
    required this.icon,
    this.onTap,
    required this.brightness,
  });

  @override
  State<_ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<_ChipButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VehicleUi.cardFor(widget.brightness).withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(VehicleUi.radiusSm),
      child: InkWell(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(VehicleUi.radiusSm),
        child: AnimatedScale(
          scale: _down ? MicroMotionSpec.pressedScale : 1.0,
          duration: MicroMotionSpec.fast,
          curve: MicroMotionSpec.emphasisCurve,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VehicleUi.radiusSm),
              border: Border.all(color: VehicleUi.glassBorderFor(widget.brightness)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: VehicleUi.accentBlue),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: VehicleUi.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
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
