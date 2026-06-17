import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';

/// Bottom sheet chọn nguồn avatar.
class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({
    super.key,
    required this.hasCustomAvatar,
  });

  final bool hasCustomAvatar;

  static Future<AvatarPickerAction?> show(BuildContext context, {required bool hasCustomAvatar}) {
    return showModalBottomSheet<AvatarPickerAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AvatarPickerSheet(hasCustomAvatar: hasCustomAvatar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final allowCamera =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
          decoration: BoxDecoration(
            color: LuxuryTokens.backgroundElevated.withValues(alpha: 0.94),
            border: Border.all(color: LuxuryTokens.glassBorder),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Đổi avatar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: LuxuryTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.photo_library_rounded,
                label: 'Chọn ảnh từ thư viện',
                onTap: () => Navigator.pop(context, AvatarPickerAction.gallery),
              ),
              if (allowCamera) ...[
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.photo_camera_rounded,
                  label: 'Chụp ảnh',
                  onTap: () => Navigator.pop(context, AvatarPickerAction.camera),
                ),
              ],
              if (hasCustomAvatar) ...[
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Xóa ảnh hiện tại',
                  destructive: true,
                  onTap: () => Navigator.pop(context, AvatarPickerAction.remove),
                ),
              ],
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.close_rounded,
                label: 'Hủy',
                muted: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AvatarPickerAction { gallery, camera, remove }

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF6B7A)
        : muted
            ? LuxuryTokens.textMuted
            : LuxuryTokens.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: muted ? 0.04 : 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LuxuryTokens.glassBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Map action → ImageSource khi cần.
extension AvatarPickerActionSource on AvatarPickerAction {
  ImageSource? get imageSource => switch (this) {
        AvatarPickerAction.gallery => ImageSource.gallery,
        AvatarPickerAction.camera => ImageSource.camera,
        AvatarPickerAction.remove => null,
      };
}
