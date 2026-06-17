import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_tracker_app/features/auth/models/user_data_models.dart';
import 'package:fuel_tracker_app/features/auth/services/user_service.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/shared/services/avatar_service.dart';

/// Session UI — mọi dữ liệu user đọc từ [UserService.currentUser], không cache global.
class UserSessionService extends ChangeNotifier {
  UserSessionService({
    UserService? userService,
    FuelService? fuelService,
  })  : _userService = userService,
        _fuelService = fuelService;

  UserService? _userService;
  FuelService? _fuelService;
  bool _bound = false;

  static const _keyDarkMode = 'dark_mode_enabled';
  static const _keyRememberMe = 'auth_remember_me';
  static const _keyEmail = 'auth_remember_email';

  static const guestName = 'Khách';
  static const guestAvatarEmoji = '👤';
  static const defaultVehicle = 'Kawasaki Ninja 400';
  static const defaultEmail = '';
  static const mockOtp = '123456';
  static const Duration _authTimeout = Duration(seconds: 10);

  bool initialized = false;
  bool darkMode = true;
  bool rememberMe = false;
  String? lastAuthError;
  String? _resetEmail;
  bool _passwordResetOtpVerified = false;
  String? _documentsPath;

  // ── State phản chiếu currentUser (không lưu SharedPreferences) ──
  bool isLoggedIn = false;
  String name = guestName;
  String email = defaultEmail;
  String phone = '';
  String vehicle = defaultVehicle;
  String avatarEmoji = guestAvatarEmoji;
  String? avatarImagePath;
  bool isPremium = false;
  String premiumPlan = '';
  String premiumExpireAt = '';
  List<TripHistoryEntry> tripHistory = const [];

  UserService? get userService => _userService;

  void bind(UserService service, {FuelService? fuelService}) {
    if (_bound) return;
    _bound = true;
    _userService = service;
    if (fuelService != null) _fuelService = fuelService;
    service.addListener(_onUserServiceChanged);
    _fuelService?.onFuelDataChanged = _persistFuelData;
  }

  void _onUserServiceChanged() {
    _syncFromUserService();
    notifyListeners();
  }

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _documentsPath = dir.path;

      await _userService?.init();

      final prefs = await SharedPreferences.getInstance();
      darkMode = prefs.getBool(_keyDarkMode) ?? true;
      rememberMe = prefs.getBool(_keyRememberMe) ?? false;
      if (rememberMe) {
        email = prefs.getString(_keyEmail) ?? defaultEmail;
      }

      _syncFromUserService();
      initialized = true;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[UserSessionService.init] $e');
      debugPrint(stack.toString());
      initialized = true;
      notifyListeners();
    }
  }

  void _syncFromUserService() {
    try {
      final user = _userService?.currentUser;

      if (user != null) {
        isLoggedIn = true;
        name = user.name.isNotEmpty ? user.name : guestName;
        email = user.email;
        phone = user.phone;
        vehicle = user.vehicle.isNotEmpty ? user.vehicle : defaultVehicle;
        avatarEmoji = user.avatarEmoji.isNotEmpty ? user.avatarEmoji : guestAvatarEmoji;
        avatarImagePath = _resolveAvatarPath(user.avatar);
        isPremium = user.premium;
        premiumPlan = user.premiumPlan;
        premiumExpireAt = user.premiumExpireAt;
        tripHistory = List<TripHistoryEntry>.from(user.tripHistory);

        _fuelService?.loadFromUserData(user.fuelData);
      } else {
        _clearUserState();
      }
    } catch (e, stack) {
      debugPrint('[UserSessionService] sync error: $e');
      debugPrint(stack.toString());
      isPremium = false;
      premiumPlan = '';
      premiumExpireAt = '';
      avatarImagePath = null;
    }
  }

  void _clearUserState() {
    isLoggedIn = false;
    name = guestName;
    phone = '';
    vehicle = defaultVehicle;
    avatarEmoji = guestAvatarEmoji;
    avatarImagePath = null;
    isPremium = false;
    premiumPlan = '';
    premiumExpireAt = '';
    tripHistory = const [];

    if (!rememberMe) email = defaultEmail;

    _fuelService?.resetToDefaults();
  }

  String? _resolveAvatarPath(String avatar) {
    if (avatar.isEmpty || _documentsPath == null) return null;
    return resolveAvatarFilePath(avatar, _documentsPath!);
  }

  /// Đường dẫn tương đối lưu trong data.json — ví dụ avatars/u001.jpg
  static String avatarRelativePath(String userId) => 'avatars/$userId.jpg';

  /// Resolve avatar từ giá trị trong currentUser.avatar.
  static String? resolveAvatarFilePath(String avatar, String documentsPath) {
    if (avatar.isEmpty) return null;

    final normalized = avatar.replaceAll('\\', '/');

    if (normalized.startsWith('avatars/')) {
      final full = '$documentsPath${Platform.pathSeparator}${normalized.replaceAll('/', Platform.pathSeparator)}';
      // Trên desktop, đôi khi file chưa kịp "existsSync" tại thời điểm rebuild.
      // Luôn trả path để Image.file tự fallback qua errorBuilder nếu lỗi.
      return full;
    }

    if (normalized.contains(Platform.pathSeparator) ||
        normalized.startsWith('/') ||
        (Platform.isWindows && normalized.contains(':'))) {
      return avatar;
    }

    // Legacy: chỉ tên file avatar_u002.jpg
    final legacy = '$documentsPath${Platform.pathSeparator}avatars${Platform.pathSeparator}$avatar';
    return legacy;
  }

  String get accountTierLabel => isPremiumActive ? 'Premium' : 'Free';

  bool get isPremiumActive {
    if (!isLoggedIn || !isPremium) return false;
    if (premiumExpireAt.isEmpty) return true;
    final parsed = DateTime.tryParse(premiumExpireAt);
    if (parsed == null) return true;
    return !DateTime.now().isAfter(parsed);
  }

  String get premiumPlanLabel => switch (premiumPlan) {
        'monthly' => 'Monthly',
        'yearly' => 'Yearly',
        'lifetime' => 'Lifetime',
        _ => premiumPlan.isEmpty ? '—' : premiumPlan,
      };

  int get tripCount => tripHistory.length;

  bool get hasCustomAvatar {
    // Chỉ cần có path là thử render; nếu file lỗi thì UI fallback emoji.
    return avatarImagePath != null && avatarImagePath!.trim().isNotEmpty;
  }

  Future<void> _persistFuelData(UserFuelData data) async {
    await _userService?.updateFuelData(data);
    _syncFromUserService();
  }

  Future<bool> login({
    required String emailInput,
    required String password,
    bool remember = false,
  }) async {
    lastAuthError = null;
    try {
      debugPrint('AUTH_START');
      final svc = _userService;
      if (svc == null) {
        lastAuthError = 'Dịch vụ tài khoản chưa sẵn sàng';
        return false;
      }

      final trimmed = emailInput.trim();
      if (trimmed.isEmpty || password.length < 6) {
        lastAuthError = 'Email hoặc mật khẩu không hợp lệ';
        return false;
      }

      final result = await svc
          .login(email: trimmed, password: password)
          .timeout(_authTimeout);
      if (!result.success) {
        lastAuthError = result.message ?? svc.lastError;
        return false;
      }

      debugPrint('AUTH_SUCCESS');

      rememberMe = remember;
      debugPrint('SESSION_SAVE_START');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, remember);
      if (remember) {
        await prefs.setString(_keyEmail, trimmed);
      } else {
        await prefs.remove(_keyEmail);
      }
      debugPrint('SESSION_SAVE_SUCCESS');

      debugPrint('LOAD_USER_DATA_START');
      _syncFromUserService();

      final currentUser = svc.currentUser;
      if (currentUser == null) {
        lastAuthError = 'Không thể tải dữ liệu người dùng';
        return false;
      }
      if ((svc.currentUserId ?? '').isEmpty) {
        await svc.restoreSessionForUser(currentUser.id).timeout(_authTimeout);
      }
      debugPrint('LOAD_USER_DATA_SUCCESS');
      notifyListeners();
      return true;
    } on TimeoutException {
      lastAuthError = 'Kết nối quá thời gian chờ';
      return false;
    } catch (e, stack) {
      debugPrint('[UserSessionService.login] $e');
      debugPrint(stack.toString());
      lastAuthError = 'Lỗi đăng nhập. Vui lòng thử lại.';
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String emailInput,
    required String phoneInput,
    required String password,
    required String confirmPassword,
  }) async {
    lastAuthError = null;
    final svc = _userService;
    if (svc == null) return false;

    if (fullName.trim().isEmpty) {
      lastAuthError = 'Họ tên không được để trống';
      return false;
    }
    if (password.length < 6 || password != confirmPassword) {
      lastAuthError = 'Mật khẩu không hợp lệ hoặc không khớp';
      return false;
    }

    final result = await svc.register(
      name: fullName.trim(),
      email: emailInput.trim(),
      phone: phoneInput.trim(),
      password: password,
    );

    if (!result.success) {
      lastAuthError = result.message ?? svc.lastError;
      return false;
    }

    _syncFromUserService();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    lastAuthError = null;

    if (isLoggedIn) {
      await _userService?.updateFuelData(
        _fuelService?.exportUserData() ?? UserFuelData.defaults,
      );
    }

    await _userService?.logout();
    _clearUserState();
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    final svc = _userService;
    if (svc == null || !isLoggedIn) return;

    final result = await svc.updatePremium(
      premium: value,
      premiumPlan: value ? premiumPlan : '',
      premiumExpireAt: value ? premiumExpireAt : '',
    );

    if (result.success) _syncFromUserService();
    notifyListeners();
  }

  Future<bool> activatePremium({
    required String planId,
    required String expireAt,
  }) async {
    final svc = _userService;
    if (svc == null || !isLoggedIn) return false;

    final result = await svc.updatePremium(
      premium: true,
      premiumPlan: planId,
      premiumExpireAt: expireAt,
    );

    if (result.success) {
      _syncFromUserService();
      notifyListeners();
      return true;
    }

    lastAuthError = result.message ?? svc.lastError;
    notifyListeners();
    return false;
  }

  Future<bool> socialLogin({required String provider, String? displayName}) async {
    try {
      final normalizedProvider = provider.toLowerCase().trim();
      if (!_isSocialProviderConfigured(normalizedProvider)) {
        if (normalizedProvider == 'google') {
          lastAuthError = 'Google Login chưa được cấu hình';
        } else if (normalizedProvider == 'facebook') {
          lastAuthError = 'Facebook Login chưa được cấu hình';
        } else {
          lastAuthError = '$provider Login chưa được cấu hình';
        }
        return false;
      }

      final svc = _userService;
      if (svc == null) return false;

      final socialEmail = '$provider.user@fueltracker.app'.toLowerCase();
      const socialPassword = 'social_demo';

      await svc.ensureReadyForAuth().timeout(_authTimeout);
      if (!await svc.emailExists(socialEmail)) {
        await svc
            .register(
          name: displayName ?? 'Người dùng $provider',
          email: socialEmail,
          phone: '',
          password: socialPassword,
        )
            .timeout(_authTimeout);
      }

      final result = await svc
          .login(email: socialEmail, password: socialPassword)
          .timeout(_authTimeout);
      if (!result.success) return false;

      _syncFromUserService();
      if ((svc.currentUserId ?? '').isEmpty && svc.currentUser != null) {
        await svc.restoreSessionForUser(svc.currentUser!.id).timeout(_authTimeout);
      }
      notifyListeners();
      return true;
    } on TimeoutException {
      lastAuthError = 'Kết nối quá thời gian chờ';
      return false;
    } catch (e, stack) {
      debugPrint('[UserSessionService.socialLogin] $e');
      debugPrint(stack.toString());
      lastAuthError = 'Đăng nhập thất bại. Vui lòng thử lại.';
      return false;
    }
  }

  bool _isSocialProviderConfigured(String provider) {
    if (provider == 'google') {
      return const bool.fromEnvironment('GOOGLE_LOGIN_CONFIGURED');
    }
    if (provider == 'facebook') {
      return const bool.fromEnvironment('FACEBOOK_LOGIN_CONFIGURED');
    }
    return true;
  }

  Future<bool> sendPasswordResetOtp(String emailInput) async {
    lastAuthError = null;
    final trimmed = emailInput.trim();
    if (!trimmed.contains('@')) return false;

    final svc = _userService;
    if (svc == null) return false;

    if (!await svc.emailExists(trimmed)) {
      lastAuthError = 'Email không tồn tại trong hệ thống';
      return false;
    }

    _resetEmail = trimmed;
    _passwordResetOtpVerified = false;
    return true;
  }

  /// Bước 2 — xác nhận OTP demo, giữ phiên đặt lại mật khẩu.
  Future<bool> confirmPasswordResetOtp(String otp) async {
    lastAuthError = null;
    final code = otp.trim();
    if (code.length < 6) {
      lastAuthError = 'Nhập đủ 6 số OTP';
      return false;
    }
    if (code != mockOtp) {
      lastAuthError = 'OTP không đúng';
      return false;
    }
    if (_resetEmail == null) {
      lastAuthError = 'Phiên đặt lại mật khẩu đã hết hạn — gửi lại OTP';
      return false;
    }
    _passwordResetOtpVerified = true;
    return true;
  }

  /// Bước 3 — đặt mật khẩu mới sau khi OTP đã xác nhận.
  Future<bool> resetPasswordAfterOtp({
    required String newPassword,
    required String confirmPassword,
    String? email,
  }) async {
    lastAuthError = null;

    if (!_passwordResetOtpVerified) {
      lastAuthError = 'Vui lòng xác nhận OTP trước';
      return false;
    }
    if (newPassword.length < 6) {
      lastAuthError = 'Mật khẩu tối thiểu 6 ký tự';
      return false;
    }
    if (newPassword != confirmPassword) {
      lastAuthError = 'Mật khẩu không khớp';
      return false;
    }

    final targetEmail = (email ?? _resetEmail)?.trim();
    final svc = _userService;
    if (targetEmail == null || targetEmail.isEmpty || svc == null) {
      lastAuthError = 'Phiên đặt lại mật khẩu đã hết hạn — gửi lại OTP';
      return false;
    }

    try {
      final result = await svc.forgotPassword(
        email: targetEmail,
        newPassword: newPassword,
      );
      if (!result.success) {
        lastAuthError = result.message ?? 'Không thể đặt lại mật khẩu';
        return false;
      }

      _resetEmail = null;
      _passwordResetOtpVerified = false;
      _syncFromUserService();
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('[UserSessionService.resetPasswordAfterOtp] $e');
      debugPrint(stack.toString());
      lastAuthError = 'Không thể đặt lại mật khẩu';
      return false;
    }
  }

  @Deprecated('Use confirmPasswordResetOtp + resetPasswordAfterOtp')
  Future<bool> verifyOtpAndResetPassword({
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!await confirmPasswordResetOtp(otp)) return false;
    return resetPasswordAfterOtp(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  Future<void> saveProfile({
    required String name,
    required String vehicle,
    required String avatarEmoji,
    String? avatarImagePath,
    bool clearAvatar = false,
  }) async {
    final svc = _userService;
    if (svc == null || !isLoggedIn) return;

    final userId = svc.currentUser?.id;
    final useImage = !clearAvatar &&
        avatarImagePath != null &&
        File(avatarImagePath).existsSync();

    String? avatarValue;
    if (useImage && userId != null) {
      avatarValue = avatarRelativePath(userId);
    }

    await svc.updateProfile(
      name: name,
      vehicle: vehicle,
      avatar: avatarValue,
      avatarEmoji: avatarEmoji,
      clearAvatar: clearAvatar || !useImage,
    );

    _syncFromUserService();
    notifyListeners();
    debugPrint('AVATAR_UI_REFRESHED');
  }

  /// Chọn ảnh từ gallery/camera, copy vào documents và cập nhật data.json ngay.
  Future<bool> pickAndPersistAvatar({
    required BuildContext context,
    required ImageSource source,
  }) async {
    final file = await AvatarService.pickImage(source: source, context: context);
    if (file == null) return false;

    final saved = await persistAvatarImage(File(file.path));
    return saved != null;
  }

  Future<String?> persistAvatarImage(File source) async {
    debugPrint('AVATAR_PICK_START');
    final svc = _userService;
    final userId = svc?.currentUser?.id;
    if (svc == null || userId == null || _documentsPath == null) return null;

    if (!await source.exists()) {
      debugPrint('[AvatarService] source file missing');
      return null;
    }

    final avatarsDir = Directory('$_documentsPath/avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }

    final relativePath = avatarRelativePath(userId);
    final dest = File('$_documentsPath${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}');

    try {
      await dest.parent.create(recursive: true);
      await source.copy(dest.path);
      debugPrint('AVATAR_SAVE_SUCCESS → ${dest.path}');
    } catch (e, st) {
      debugPrint('[AvatarService] copy failed: $e\n$st');
      return null;
    }

    await svc.updateProfile(avatar: relativePath);
    debugPrint('AVATAR_JSON_UPDATED → $relativePath');

    _syncFromUserService();
    notifyListeners();
    debugPrint('AVATAR_UI_REFRESHED');

    return dest.path;
  }

  /// Xóa ảnh avatar — quay về emoji, cập nhật data.json.
  Future<void> clearAvatarImage() async {
    final svc = _userService;
    final userId = svc?.currentUser?.id;
    if (svc == null || userId == null || _documentsPath == null) return;

    final relativePath = avatarRelativePath(userId);
    final file = File('$_documentsPath${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}');
    if (await file.exists()) {
      await file.delete();
    }

    // Legacy file
    final legacy = File('$_documentsPath/avatars/avatar_$userId.jpg');
    if (await legacy.exists()) {
      await legacy.delete();
    }

    await svc.updateProfile(clearAvatar: true);
    debugPrint('AVATAR_JSON_UPDATED → cleared');

    _syncFromUserService();
    notifyListeners();
    debugPrint('AVATAR_UI_REFRESHED');
  }

  Future<void> setDarkMode(bool enabled) async {
    darkMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
    notifyListeners();
  }
}
