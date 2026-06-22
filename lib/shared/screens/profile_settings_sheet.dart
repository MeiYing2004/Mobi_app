import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/services/avatar_service.dart';
import 'package:fuel_tracker_app/shared/widgets/avatar/avatar_picker_sheet.dart';
import 'package:fuel_tracker_app/shared/widgets/avatar/user_avatar_widget.dart';
import 'package:fuel_tracker_app/shared/widgets/ios_style_widgets.dart';
import 'package:fuel_tracker_app/core/config/osm_config.dart';
import 'package:fuel_tracker_app/shared/screens/security/change_password_screen.dart';
import 'package:fuel_tracker_app/shared/screens/security/login_devices_screen.dart';
import 'package:fuel_tracker_app/shared/screens/security/privacy_screen.dart';

enum _DialogButtonKind { neutral, danger }

class _SettingsActionItem {
  const _SettingsActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

/// Bottom sheet cài đặt & hồ sơ người dùng.
class ProfileSettingsSheet extends StatefulWidget {
  const ProfileSettingsSheet({super.key});

  @override
  State<ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<ProfileSettingsSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _vehicleCtrl;

  late String _avatarEmoji;
  bool _preferEmoji = false;
  bool _pickingAvatar = false;

  String? _nameError;
  bool _saving = false;

  static const _avatarChoices = ['🏍️', '🧑‍🚀', '😎', '🔥', '🚗', '🛵'];

  @override
  void initState() {
    super.initState();
    final session = context.read<UserSessionService>();
    _nameCtrl = TextEditingController(text: session.name);
    _vehicleCtrl = TextEditingController(text: session.vehicle);
    _avatarEmoji = session.avatarEmoji;
    _preferEmoji = !session.hasCustomAvatar;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  void _showGlassNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: IosGlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? const Color(0xFFFF4D6D) : const Color(0xFF30D158),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: IosGlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đăng xuất?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bạn có chắc muốn đăng xuất khỏi tài khoản hiện tại?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: 'Hủy',
                        onPressed: () => Navigator.pop(ctx, false),
                        kind: _DialogButtonKind.neutral,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogButton(
                        label: 'Đăng xuất',
                        onPressed: () => Navigator.pop(ctx, true),
                        kind: _DialogButtonKind.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _openAvatarPicker() async {
    final session = context.read<UserSessionService>();
    if (!session.isLoggedIn || _pickingAvatar) return;

    final action = await AvatarPickerSheet.show(
      context,
      hasCustomAvatar: session.hasCustomAvatar,
    );
    if (!mounted || action == null) return;

    setState(() => _pickingAvatar = true);

    final svc = context.read<UserSessionService>();
    var ok = false;

    try {
      switch (action) {
        case AvatarPickerAction.gallery:
          ok = await svc.pickAndPersistAvatar(
            context: context,
            source: ImageSource.gallery,
          );
          if (ok) _preferEmoji = false;
          break;
        case AvatarPickerAction.camera:
          ok = await svc.pickAndPersistAvatar(
            context: context,
            source: ImageSource.camera,
          );
          if (ok) _preferEmoji = false;
          break;
        case AvatarPickerAction.remove:
          await svc.clearAvatarImage();
          ok = true;
          _preferEmoji = true;
          break;
      }
    } catch (e) {
      debugPrint('[ProfileSettingsSheet] Lỗi Avatar: $e');
      ok = false;
    }

    if (!mounted) return;
    setState(() => _pickingAvatar = false);

    if (ok) {
      if (action != AvatarPickerAction.remove) {
        _showGlassNotification('Đã cập nhật avatar thành công!');
      } else {
        _showGlassNotification('Đã xóa ảnh avatar');
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Tên không được để trống');
      return;
    }

    setState(() {
      _nameError = null;
      _saving = true;
    });

    final session = context.read<UserSessionService>();
    final vehicle = _vehicleCtrl.text.trim();
    final useEmojiOnly = _preferEmoji || !session.hasCustomAvatar;

    await session.saveProfile(
      name: name,
      vehicle: vehicle.isEmpty ? UserSessionService.defaultVehicle : vehicle,
      avatarEmoji: _avatarEmoji,
      avatarImagePath: useEmojiOnly ? null : session.avatarImagePath,
      clearAvatar: useEmojiOnly,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    _showGlassNotification('Đã lưu hồ sơ thành công');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final contentPad = size.width >= 420 ? 24.0 : 16.0;
    final safeTop = MediaQuery.paddingOf(context).top;
    final titleGap = safeTop > 0 ? 24.0 : 16.0;
    final onSurface = theme.colorScheme.onSurface;
    final muted = theme.textTheme.bodySmall?.color ?? onSurface;

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050816),
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            contentPad,
            titleGap,
            contentPad,
            24 + safeBottom,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetTitle(
                  title: 'Cài đặt',
                  subtitle: 'Hồ sơ người dùng',
                  muted: muted,
                  onClose: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: 16),

                const _SectionHeader(title: 'Account'),
                const SizedBox(height: 12),
                _AccountHeroCard(
                  session: session,
                  pickingAvatar: _pickingAvatar,
                  onAvatarTap: session.isLoggedIn ? _openAvatarPicker : null,
                ),

                const SizedBox(height: 18),
                const _SectionHeader(title: 'Profile'),
                const SizedBox(height: 12),
                _EditableProfileFieldCard(
                  icon: Icons.person_rounded,
                  title: 'Tên hiển thị',
                  subtitle: 'Nickname',
                  controller: _nameCtrl,
                  errorText: _nameError,
                ),
                const SizedBox(height: 12),
                _EditableProfileFieldCard(
                  icon: Icons.directions_car_filled_rounded,
                  title: 'Xe hiện tại',
                  subtitle: 'Vehicle',
                  controller: _vehicleCtrl,
                ),

                const SizedBox(height: 18),
                const _SectionHeader(title: 'Appearance'),
                const SizedBox(height: 12),
                _DarkModeCard(
                  value: session.darkMode,
                  onChanged: session.setDarkMode,
                ),

                const SizedBox(height: 18),
                const _SectionHeader(title: 'Avatar'),
                const SizedBox(height: 12),
                _AvatarHero(
                  session: session,
                  muted: muted,
                  pickingAvatar: _pickingAvatar,
                  onTap: session.isLoggedIn ? _openAvatarPicker : null,
                ),
                const SizedBox(height: 14),
                _AvatarPresetGrid(
                  choices: _avatarChoices,
                  selected: _preferEmoji && !session.hasCustomAvatar ? _avatarEmoji : null,
                  onPick: (emoji) => setState(() {
                    _avatarEmoji = emoji;
                    _preferEmoji = true;
                  }),
                ),

                const SizedBox(height: 18),
                const _SectionHeader(title: 'Premium'),
                const SizedBox(height: 12),
                _PremiumMembershipCard(session: session),

                const SizedBox(height: 18),
                const _SectionHeader(title: 'Security'),
                const SizedBox(height: 12),
                _SettingsActionRow(
                  items: [
                    _SettingsActionItem(
                      icon: Icons.lock_rounded,
                      title: 'Đổi mật khẩu',
                      subtitle: 'Bảo mật',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
                    ),
                    _SettingsActionItem(
                      icon: Icons.phone_iphone_rounded,
                      title: 'Thiết bị đăng nhập',
                      subtitle: 'Phiên đăng nhập',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginDevicesScreen(),
                        ),
                      ),
                    ),
                    _SettingsActionItem(
                      icon: Icons.shield_rounded,
                      title: 'Quyền riêng tư',
                      subtitle: 'Dữ liệu & quyền',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const _SectionHeader(title: 'About'),
                const SizedBox(height: 12),
                _AboutCard(
                  version: OsmConfig.appVersion,
                  developer: 'Mobiapp',
                ),

                const SizedBox(height: 18),
                _SaveButton(
                  saving: _saving,
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 12),
                _LogoutButton(
                  enabled: session.isLoggedIn && !_saving,
                  onLogout: () async {
                    final nav = Navigator.of(context);
                    final svc = session;
                    final ok = await _confirmLogout(context);
                    if (!ok || !mounted) return;
                    await svc.logout();
                    if (!mounted) return;
                    nav.pop();
                  },
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .slideY(begin: 0.02, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({
    required this.title,
    required this.subtitle,
    required this.muted,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final Color muted;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: muted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountHeroCard extends StatelessWidget {
  const _AccountHeroCard({
    required this.session,
    required this.pickingAvatar,
    required this.onAvatarTap,
  });

  final UserSessionService session;
  final bool pickingAvatar;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelService>();
    final name = session.name.isNotEmpty ? session.name : 'Guest';
    final email = session.email.isNotEmpty ? session.email : '—';
    final tank = fuel.tankCapacityLiters;
    final efficiency = tank > 0
        ? ((fuel.currentFuelLiters / tank) * 100).clamp(0, 100).round()
        : null;

    return IosGlassCard(
      borderRadius: 24,
      blur: 22,
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: _GlowOrb(
              size: 180,
              color: VehicleUi.accentBlue.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -70,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFFFFD166).withValues(alpha: 0.22),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PremiumAvatar(
                      size: 92,
                      fontSize: 36,
                      picking: pickingAvatar,
                      onTap: onAvatarTap,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PremiumShimmerBadge(
                            enabled: session.isPremiumActive,
                            label: session.isPremiumActive ? 'Premium Member' : 'Free Member',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      icon: Icons.directions_car_rounded,
                      label: 'Trips',
                      value: '${session.tripCount}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      icon: Icons.local_gas_station_rounded,
                      label: 'Fuel',
                      value: '${fuel.currentFuelLiters.toStringAsFixed(0)}L',
                    ),
                  ),
                  if (session.isPremiumActive) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.show_chart_rounded,
                        label: 'Efficiency',
                        value: efficiency == null ? '—' : '$efficiency%',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAvatar extends StatelessWidget {
  const _PremiumAvatar({
    required this.size,
    required this.fontSize,
    required this.picking,
    required this.onTap,
  });
  final double size;
  final double fontSize;
  final bool picking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tapEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF5BB8FF), Color(0xFF3B7DDF), Color(0xFF1E4A9A)],
          ),
          boxShadow: [
            BoxShadow(
              color: VehicleUi.accentBlue.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: UserAvatarWidget(
                size: size - 4,
                fontSize: fontSize,
                onTap: null,
              ),
            ),
            if (picking)
              Container(
                width: size - 4,
                height: size - 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(26),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            if (tapEnabled && !picking)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5BB8FF), Color(0xFF1E4A9A)],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: VehicleUi.accentBlue.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    ).animate().scale(
      duration: 260.ms,
      curve: Curves.easeOutBack,
      begin: const Offset(0.98, 0.98),
      end: const Offset(1, 1),
    );
  }
}

class _PremiumShimmerBadge extends StatefulWidget {
  const _PremiumShimmerBadge({required this.enabled, required this.label});
  final bool enabled;
  final String label;

  @override
  State<_PremiumShimmerBadge> createState() => _PremiumShimmerBadgeState();
}

class _PremiumShimmerBadgeState extends State<_PremiumShimmerBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.enabled
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE08A), Color(0xFFFFC857), Color(0xFFB7791F)],
    )
        : LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.18),
        Colors.white.withValues(alpha: 0.08),
      ],
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final shimmer = LinearGradient(
          begin: Alignment(-1 + 2 * t, -0.2),
          end: Alignment(-0.2 + 2 * t, 0.2),
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: widget.enabled ? 0.35 : 0.18),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          constraints: const BoxConstraints(minWidth: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: base,
            border: Border.all(
              color: Colors.white.withValues(alpha: widget.enabled ? 0.22 : 0.12),
              width: 1,
            ),
            boxShadow: widget.enabled
                ? [
              BoxShadow(
                color: const Color(0xFFFFC857).withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ]
                : null,
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => shimmer.createShader(r),
            child: Text(
              widget.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: widget.enabled ? const Color(0xFF2B1600) : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditableProfileFieldCard extends StatelessWidget {
  const _EditableProfileFieldCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    this.errorText,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IosGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: subtitle,
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                    errorText: errorText,
                    errorStyle: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFFF6B7A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkModeCard extends StatelessWidget {
  const _DarkModeCard({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return IosGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF0B1025)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(child: Text('🌙', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sử dụng giao diện tối',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AvatarHero extends StatelessWidget {
  const _AvatarHero({
    required this.session,
    required this.muted,
    required this.pickingAvatar,
    required this.onTap,
  });
  final UserSessionService session;
  final Color muted;
  final bool pickingAvatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IosGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          _PremiumAvatar(size: 120, fontSize: 48, picking: pickingAvatar, onTap: onTap),
          const SizedBox(height: 12),
          Text(
            session.isLoggedIn ? 'Chạm để thay đổi ảnh đại diện' : 'Đăng nhập để đổi avatar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted.withValues(alpha: 0.9),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPresetGrid extends StatelessWidget {
  const _AvatarPresetGrid({
    required this.choices,
    required this.selected,
    required this.onPick,
  });
  final List<String> choices;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final item = screenW >= 600 ? 92.0 : 80.0;
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: choices.map((e) => _PresetMiniCard(
        size: item,
        emoji: e,
        selected: selected == e,
        onTap: () => onPick(e),
      )).toList(growable: false),
    );
  }
}

class _PresetMiniCard extends StatefulWidget {
  const _PresetMiniCard({
    required this.size,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final double size;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PresetMiniCard> createState() => _PresetMiniCardState();
}

class _PresetMiniCardState extends State<_PresetMiniCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.selected
        ? VehicleUi.accentBlue.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.14);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: border, width: widget.selected ? 1.6 : 1.0),
            boxShadow: widget.selected
                ? [BoxShadow(color: VehicleUi.accentBlue.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 12))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 12))],
          ),
          child: Center(
            child: Text(
              widget.emoji,
              style: TextStyle(
                fontSize: widget.size >= 92 ? 30 : 28,
                shadows: widget.selected ? [Shadow(color: VehicleUi.accentBlue.withValues(alpha: 0.35), blurRadius: 14)] : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumMembershipCard extends StatelessWidget {
  const _PremiumMembershipCard({required this.session});
  final UserSessionService session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IosGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE08A), Color(0xFFB7791F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC857).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF2B1600), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Membership',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Plan, trạng thái & quản lý',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0x99FFFFFF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _KeyValueRow(label: 'Status', value: session.isPremiumActive ? 'Active' : 'Free'),
          const SizedBox(height: 8),
          _KeyValueRow(label: 'Plan', value: session.isPremiumActive ? session.premiumPlanLabel : '—'),
          const SizedBox(height: 8),
          _KeyValueRow(label: 'Expire', value: session.isPremiumActive && session.premiumExpireAt.isNotEmpty ? session.premiumExpireAt : '—'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                'Manage Membership',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({required this.items});
  final List<_SettingsActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == items.last ? 0 : 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: i.onTap,
              borderRadius: BorderRadius.circular(24),
              child: IosGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: 24,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Icon(i.icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            i.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.35)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.version, required this.developer});
  final String version;
  final String developer;

  @override
  Widget build(BuildContext context) {
    return IosGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'App Information',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _KeyValueRow(label: 'Version', value: version),
          const SizedBox(height: 8),
          const _KeyValueRow(label: 'Build', value: '—'),
          const SizedBox(height: 8),
          _KeyValueRow(label: 'Developer', value: developer),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saving, required this.onPressed});
  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: saving
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
            : Text('Lưu hồ sơ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onPrimary)),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.enabled, required this.onLogout});
  final bool enabled;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: enabled ? onLogout : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF4D6D), Color(0xFFB91C1C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D6D).withValues(alpha: 0.25),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Đăng xuất',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onPressed, required this.kind});
  final String label;
  final VoidCallback onPressed;
  final _DialogButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final isDanger = kind == _DialogButtonKind.danger;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isDanger
              ? const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : LinearGradient(colors: [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withValues(alpha: isDanger ? 0.16 : 0.12)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2),
          ),
        ),
      ),
    );
  }
}