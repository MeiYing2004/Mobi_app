import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';

/// Xử lý quyền + image_picker cho avatar (Android / iOS / Windows / Web).
abstract final class AvatarService {
  static final _picker = ImagePicker();

  static void _log(String message) => debugPrint(message);

  /// Chọn ảnh từ thư viện hoặc camera.
  static Future<XFile?> pickImage({
    required ImageSource source,
    required BuildContext context,
  }) async {
    _log('AVATAR_PICK_START');

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return _pickDesktopImage(source: source, context: context);
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final granted = await _ensurePermission(source, context);
      if (!granted) return null;
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        _log('AVATAR_PICK_SUCCESS');
      }
      return file;
    } catch (e, st) {
      debugPrint('[AvatarService] pick failed: $e\n$st');
      if (context.mounted) {
        _showErrorDialog(
          context,
          title: 'Không thể chọn ảnh',
          message: 'Vui lòng thử lại hoặc chọn ảnh khác.',
        );
      }
      return null;
    }
  }

  static Future<XFile?> _pickDesktopImage({
    required ImageSource source,
    required BuildContext context,
  }) async {
    if (source == ImageSource.camera) {
      if (context.mounted) {
        await _showErrorDialog(
          context,
          title: 'Desktop chưa hỗ trợ camera',
          message: 'Vui lòng chọn ảnh từ thư viện trên Windows/macOS/Linux.',
        );
      }
      return null;
    }

    try {
      const images = XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );
      final selected = await openFile(acceptedTypeGroups: [images]);
      if (selected == null) return null;
      _log('AVATAR_PICK_SUCCESS');
      return XFile(selected.path);
    } catch (e, st) {
      debugPrint('[AvatarService.desktopPick] failed: $e\n$st');
      if (context.mounted) {
        await _showErrorDialog(
          context,
          title: 'Không thể chọn ảnh',
          message: 'Vui lòng thử lại hoặc chọn ảnh khác.',
        );
      }
      return null;
    }
  }

  static Future<bool> _ensurePermission(
    ImageSource source,
    BuildContext context,
  ) async {
    if (source == ImageSource.camera) {
      return _requestPermission(context, Permission.camera, 'Camera');
    }

    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;

      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;

      final denied = photos.isPermanentlyDenied || storage.isPermanentlyDenied;
      if (denied && context.mounted) {
        await _showPermissionDialog(
          context,
          title: 'Cần quyền truy cập ảnh',
          message:
              'Fuel Tracker cần quyền đọc ảnh để đặt avatar. Vui lòng bật trong Cài đặt.',
        );
      }
      return false;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied && context.mounted) {
        await _showPermissionDialog(
          context,
          title: 'Cần quyền thư viện ảnh',
          message: 'Vui lòng cho phép truy cập ảnh trong Cài đặt iOS.',
        );
      }
      return false;
    }

    return true;
  }

  static Future<bool> _requestPermission(
    BuildContext context,
    Permission permission,
    String label,
  ) async {
    var status = await permission.status;
    if (status.isGranted) return true;

    status = await permission.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      await _showPermissionDialog(
        context,
        title: 'Cần quyền $label',
        message: 'Vui lòng bật quyền $label trong Cài đặt thiết bị.',
      );
    }
    return false;
  }

  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxuryTokens.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: LuxuryTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: LuxuryTokens.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: GoogleFonts.inter(color: LuxuryTokens.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(
              'Mở Cài đặt',
              style: GoogleFonts.inter(
                color: LuxuryTokens.neonBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxuryTokens.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.inter(color: LuxuryTokens.textPrimary)),
        content: Text(message, style: GoogleFonts.inter(color: LuxuryTokens.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.inter(color: LuxuryTokens.neonBlue)),
          ),
        ],
      ),
    );
  }
}
