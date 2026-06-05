import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu hồ sơ người dùng và dark mode qua SharedPreferences.
class UserSessionService extends ChangeNotifier {
  static const _keyName = 'profile_name';
  static const _keyVehicle = 'profile_vehicle';
  static const _keyAvatarEmoji = 'profile_avatar_emoji';
  static const _keyAvatarImage = 'profile_avatar_image';
  static const _keyDarkMode = 'dark_mode_enabled';

  static const defaultName = 'Minh Hoàng';
  static const defaultVehicle = 'Kawasaki Ninja 400';
  static const defaultAvatarEmoji = '🏍️';

  bool initialized = false;
  String name = defaultName;
  String vehicle = defaultVehicle;
  String avatarEmoji = defaultAvatarEmoji;
  String? avatarImagePath;
  bool darkMode = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString(_keyName) ?? defaultName;
    vehicle = prefs.getString(_keyVehicle) ?? defaultVehicle;
    avatarEmoji = prefs.getString(_keyAvatarEmoji) ?? defaultAvatarEmoji;
    avatarImagePath = prefs.getString(_keyAvatarImage);
    darkMode = prefs.getBool(_keyDarkMode) ?? true;
    initialized = true;
    notifyListeners();
  }

  Future<void> saveProfile({
    required String name,
    required String vehicle,
    required String avatarEmoji,
    String? avatarImagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    this.name = name;
    this.vehicle = vehicle;
    this.avatarEmoji = avatarEmoji;
    this.avatarImagePath = avatarImagePath;

    await prefs.setString(_keyName, name);
    await prefs.setString(_keyVehicle, vehicle);
    await prefs.setString(_keyAvatarEmoji, avatarEmoji);
    if (avatarImagePath == null) {
      await prefs.remove(_keyAvatarImage);
    } else {
      await prefs.setString(_keyAvatarImage, avatarImagePath);
    }
    notifyListeners();
  }

  Future<String?> persistAvatarImage(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${dir.path}/avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    final dest = File(
      '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await source.copy(dest.path);
    return dest.path;
  }

  Future<void> setDarkMode(bool enabled) async {
    darkMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
    notifyListeners();
  }

  bool get hasCustomAvatar {
    final path = avatarImagePath;
    return path != null && File(path).existsSync();
  }
}
