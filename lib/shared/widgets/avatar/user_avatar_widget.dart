import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';

/// Avatar dùng chung — đọc từ [UserSessionService.currentUser] qua session.
class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    super.key,
    this.size = 44,
    this.fontSize,
    this.showGuestFallback = true,
    this.onTap,
  });

  final double size;
  final double? fontSize;
  final bool showGuestFallback;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    final emojiSize = fontSize ?? size * 0.46;

    Widget avatar;
    if (session.hasCustomAvatar) {
      avatar = ClipOval(
        child: Image.file(
          File(session.avatarImagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiFallback(session, emojiSize),
        ),
      );
    } else {
      avatar = _emojiFallback(session, emojiSize);
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _emojiFallback(UserSessionService session, double emojiSize) {
    final emoji = session.isLoggedIn
        ? session.avatarEmoji
        : (showGuestFallback ? UserSessionService.guestAvatarEmoji : '👤');

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: VehicleUi.accentGradient,
      ),
      child: Text(emoji, style: TextStyle(fontSize: emojiSize, height: 1)),
    );
  }
}
