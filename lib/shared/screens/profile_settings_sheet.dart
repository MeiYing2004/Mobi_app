import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/ios_style_widgets.dart';

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
  String? _avatarImagePath;

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
    _avatarImagePath = session.avatarImagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final session = context.read<UserSessionService>();
    final savedPath = await session.persistAvatarImage(File(file.path));
    if (!mounted || savedPath == null) return;

    setState(() => _avatarImagePath = savedPath);
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

    final vehicle = _vehicleCtrl.text.trim();
    await context.read<UserSessionService>().saveProfile(
          name: name,
          vehicle: vehicle.isEmpty ? UserSessionService.defaultVehicle : vehicle,
          avatarEmoji: _avatarEmoji,
          avatarImagePath: _avatarImagePath,
        );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu hồ sơ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF475569);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + safeBottom),
        child: IosGlassCard(
          borderRadius: 28,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cài đặt',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hồ sơ người dùng',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSwitchRow(
                  title: 'Dark mode',
                  subtitle: 'Bật giao diện tối',
                  value: session.darkMode,
                  onChanged: session.setDarkMode,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    hint: 'Tên hiển thị',
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vehicleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(hint: 'Xe đang dùng'),
                ),
                const SizedBox(height: 18),
                Text(
                  'Avatar',
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._avatarChoices.map(_emojiAvatarChip),
                    _galleryAvatarChip(),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: VehicleUi.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Lưu hồ sơ',
                            style: TextStyle(fontWeight: FontWeight.w800),
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

  Widget _emojiAvatarChip(String emoji) {
    final selected = _avatarImagePath == null && _avatarEmoji == emoji;
    return InkWell(
      onTap: () => setState(() {
        _avatarEmoji = emoji;
        _avatarImagePath = null;
      }),
      borderRadius: BorderRadius.circular(999),
      child: _avatarCircle(
        selected: selected,
        child: Text(emoji, style: const TextStyle(fontSize: 21)),
      ),
    );
  }

  Widget _galleryAvatarChip() {
    final hasImage =
        _avatarImagePath != null && File(_avatarImagePath!).existsSync();
    return InkWell(
      onTap: _pickAvatarFromGallery,
      borderRadius: BorderRadius.circular(999),
      child: _avatarCircle(
        selected: hasImage,
        child: hasImage
            ? ClipOval(
                child: Image.file(
                  File(_avatarImagePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white.withValues(alpha: 0.75),
                size: 22,
              ),
      ),
    );
  }

  Widget _avatarCircle({required bool selected, required Widget child}) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: (selected
                  ? VehicleUi.accentBlue
                  : Colors.white.withValues(alpha: 0.2))
              .withValues(alpha: 0.85),
          width: selected ? 1.8 : 1.0,
        ),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      errorText: errorText,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: VehicleUi.accentBlue.withValues(alpha: 0.7),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
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

/// Avatar trên header bản đồ.
class ProfileAvatarBadge extends StatelessWidget {
  final double size;
  final double fontSize;

  const ProfileAvatarBadge({
    super.key,
    this.size = 44,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    if (session.hasCustomAvatar) {
      return ClipOval(
        child: Image.file(
          File(session.avatarImagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Text(
      session.avatarEmoji,
      style: TextStyle(fontSize: fontSize, height: 1),
    );
  }
}
