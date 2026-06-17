import 'package:flutter/foundation.dart';

import 'package:fuel_tracker_app/features/auth/data/user_data_store.dart';
import 'package:fuel_tracker_app/features/auth/models/user_data_models.dart';
import 'package:fuel_tracker_app/features/auth/models/user_model.dart';

/// Quản lý tài khoản local qua data.json — mỗi user có dữ liệu riêng.
class UserService extends ChangeNotifier {
  UserService({UserDataStore? store}) : _store = store ?? UserDataStore();

  final UserDataStore _store;

  bool initialized = false;
  String? lastError;
  UserModel? currentUser;

  UserDatabase get database => _store.database;

  String? get dataFilePath => _store.activeFilePath;

  String? get currentUserId => _store.database.session.currentUserId.isEmpty
      ? null
      : _store.database.session.currentUserId;

  bool get isLoggedIn => currentUser != null;

  Future<void> init() async {
    try {
      await _store.ensureReady();
      await _restoreSession();
      initialized = true;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[UserService.init] $e');
      debugPrint(stack.toString());
      initialized = true;
      currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _restoreSession() async {
    final id = _store.database.session.currentUserId;
    if (id.isEmpty) {
      currentUser = null;
      return;
    }
    currentUser = _findUserById(id);
    if (currentUser == null) {
      await _clearSessionInFile();
    }
  }

  UserModel? _findUserById(String id) {
    for (final u in _store.database.users) {
      if (u.id == id) return u;
    }
    return null;
  }

  UserModel? _findUserByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final u in _store.database.users) {
      if (u.email.trim().toLowerCase() == normalized) return u;
    }
    return null;
  }

  String _nextUserId() {
    var max = 0;
    for (final u in _store.database.users) {
      final num = int.tryParse(u.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (num > max) max = num;
    }
    return 'u${(max + 1).toString().padLeft(3, '0')}';
  }

  Future<void> _persistUser(UserModel user) async {
    final users = _store.database.users
        .map((u) => u.id == user.id ? user : u)
        .toList();
    _store.replaceDatabase(_store.database.copyWith(users: users));
    await _store.save();
    if (currentUser?.id == user.id) {
      currentUser = user;
    }
    notifyListeners();
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    lastError = null;
    await _store.ensureReady();

    if (_findUserByEmail(email) != null) {
      lastError = 'Email đã được đăng ký';
      return AuthResult(success: false, message: lastError);
    }

    final now = DateTime.now().toIso8601String().split('T').first;
    final user = UserModel(
      id: _nextUserId(),
      name: name.trim(),
      email: email.trim(),
      password: password,
      phone: phone.trim(),
      premium: false,
      createdAt: now,
      lastLogin: now,
      tripHistory: const [],
      fuelData: UserFuelData.defaults,
    );

    final users = List<UserModel>.from(_store.database.users)..add(user);
    _store.replaceDatabase(_store.database.copyWith(users: users));
    await _store.save();

    return login(email: email, password: password);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    lastError = null;
    try {
      await _store.ensureReady();

      final user = _findUserByEmail(email);
      if (user == null || user.password != password) {
        lastError = 'Email hoặc mật khẩu không đúng';
        return AuthResult(success: false, message: lastError);
      }

      final now = DateTime.now().toIso8601String().split('T').first;
      final updated = user.copyWith(lastLogin: now);
      final users = _store.database.users
          .map((u) => u.id == updated.id ? updated : u)
          .toList();

      _store.replaceDatabase(
        _store.database.copyWith(
          users: users,
          session: AppSession(currentUserId: updated.id),
        ),
      );
      await _store.save();

      currentUser = updated;
      notifyListeners();
      return AuthResult(success: true, user: updated);
    } catch (e, stack) {
      debugPrint('[UserService.login] $e');
      debugPrint(stack.toString());
      lastError = 'Lỗi đăng nhập';
      return AuthResult(success: false, message: lastError);
    }
  }

  Future<void> logout() async {
    lastError = null;
    currentUser = null;
    await _clearSessionInFile();
    notifyListeners();
  }

  Future<void> _clearSessionInFile() async {
    _store.replaceDatabase(_store.database.copyWith(clearSession: true));
    await _store.save();
  }

  Future<bool> emailExists(String email) async {
    await _store.ensureReady();
    return _findUserByEmail(email) != null;
  }

  Future<AuthResult> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    lastError = null;
    try {
      await _store.ensureReady();

      final user = _findUserByEmail(email);
      if (user == null) {
        lastError = 'Không tìm thấy tài khoản với email này';
        return AuthResult(success: false, message: lastError);
      }

      final updated = user.copyWith(password: newPassword);
      await _persistUser(updated);
      return AuthResult(success: true, user: updated);
    } catch (e, stack) {
      debugPrint('[UserService.forgotPassword] $e');
      debugPrint(stack.toString());
      lastError = 'Không thể lưu mật khẩu mới';
      return AuthResult(success: false, message: lastError);
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastError = null;
    final active = currentUser;
    if (active == null) {
      lastError = 'Chưa đăng nhập';
      return AuthResult(success: false, message: lastError);
    }

    if (active.password != currentPassword) {
      lastError = 'Mật khẩu hiện tại không đúng';
      return AuthResult(success: false, message: lastError);
    }

    if (newPassword.trim().length < 6) {
      lastError = 'Mật khẩu mới phải có ít nhất 6 ký tự';
      return AuthResult(success: false, message: lastError);
    }

    if (newPassword == currentPassword) {
      lastError = 'Mật khẩu mới phải khác mật khẩu hiện tại';
      return AuthResult(success: false, message: lastError);
    }

    await _persistUser(active.copyWith(password: newPassword));
    return AuthResult(success: true, user: currentUser);
  }

  Future<AuthResult> updatePremium({
    bool premium = true,
    String premiumPlan = '',
    String premiumExpireAt = '',
  }) async {
    lastError = null;
    final active = currentUser;
    if (active == null) {
      lastError = 'Chưa đăng nhập';
      return AuthResult(success: false, message: lastError);
    }

    await _persistUser(
      active.copyWith(
        premium: premium,
        premiumPlan: premium ? premiumPlan : '',
        premiumExpireAt: premium ? premiumExpireAt : '',
      ),
    );
    return AuthResult(success: true, user: currentUser);
  }

  Future<AuthResult> updateProfile({
    String? name,
    String? vehicle,
    String? avatar,
    String? avatarEmoji,
    bool clearAvatar = false,
  }) async {
    lastError = null;
    final active = currentUser;
    if (active == null) {
      lastError = 'Chưa đăng nhập';
      return AuthResult(success: false, message: lastError);
    }

    await _persistUser(
      active.copyWith(
        name: name ?? active.name,
        vehicle: vehicle ?? active.vehicle,
        avatar: clearAvatar ? '' : (avatar ?? active.avatar),
        avatarEmoji: avatarEmoji ?? active.avatarEmoji,
      ),
    );
    return AuthResult(success: true, user: currentUser);
  }

  Future<AuthResult> updateFuelData(UserFuelData fuelData) async {
    lastError = null;
    final active = currentUser;
    if (active == null) {
      lastError = 'Chưa đăng nhập';
      return AuthResult(success: false, message: lastError);
    }

    await _persistUser(active.copyWith(fuelData: fuelData));
    return AuthResult(success: true, user: currentUser);
  }

  Future<AuthResult> addTripHistory(TripHistoryEntry entry) async {
    lastError = null;
    final active = currentUser;
    if (active == null) {
      lastError = 'Chưa đăng nhập';
      return AuthResult(success: false, message: lastError);
    }

    final history = List<TripHistoryEntry>.from(active.tripHistory)..insert(0, entry);
    await _persistUser(active.copyWith(tripHistory: history));
    return AuthResult(success: true, user: currentUser);
  }

  Future<void> reload() async {
    await _store.reload();
    await _restoreSession();
    notifyListeners();
  }

  Future<void> restoreSessionForUser(String userId) async {
    await _store.ensureReady();
    final user = _findUserById(userId);
    if (user == null) return;
    _store.replaceDatabase(
      _store.database.copyWith(session: AppSession(currentUserId: user.id)),
    );
    await _store.save();
    currentUser = user;
    notifyListeners();
  }

  Future<void> ensureReadyForAuth() => _store.ensureReady();
}
