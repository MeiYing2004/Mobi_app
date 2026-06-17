import 'package:fuel_tracker_app/features/auth/models/user_data_models.dart';

/// Tài khoản người dùng — lưu trong data.json.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.premium,
    required this.createdAt,
    this.avatar = '',
    this.avatarEmoji = '🏍️',
    this.vehicle = 'Kawasaki Ninja 400',
    this.premiumPlan = '',
    this.premiumExpireAt = '',
    this.lastLogin = '',
    this.tripHistory = const [],
    this.fuelData = UserFuelData.defaults,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String avatar;
  final String avatarEmoji;
  final String vehicle;
  final bool premium;
  final String premiumPlan;
  final String premiumExpireAt;
  final String createdAt;
  final String lastLogin;
  final List<TripHistoryEntry> tripHistory;
  final UserFuelData fuelData;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['tripHistory'] as List<dynamic>? ?? [];
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      avatarEmoji: json['avatarEmoji'] as String? ?? '🏍️',
      vehicle: json['vehicle'] as String? ?? 'Kawasaki Ninja 400',
      premium: json['premium'] as bool? ?? false,
      premiumPlan: json['premiumPlan'] as String? ?? '',
      premiumExpireAt: json['premiumExpireAt'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      lastLogin: json['lastLogin'] as String? ?? '',
      tripHistory: rawHistory
          .whereType<Map<String, dynamic>>()
          .map(TripHistoryEntry.fromJson)
          .toList(),
      fuelData: UserFuelData.fromJson(
        json['fuelData'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'avatar': avatar,
        'avatarEmoji': avatarEmoji,
        'vehicle': vehicle,
        'premium': premium,
        'premiumPlan': premiumPlan,
        'premiumExpireAt': premiumExpireAt,
        'createdAt': createdAt,
        'lastLogin': lastLogin,
        'tripHistory': tripHistory.map((e) => e.toJson()).toList(),
        'fuelData': fuelData.toJson(),
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? avatar,
    String? avatarEmoji,
    String? vehicle,
    bool? premium,
    String? premiumPlan,
    String? premiumExpireAt,
    String? createdAt,
    String? lastLogin,
    List<TripHistoryEntry>? tripHistory,
    UserFuelData? fuelData,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      vehicle: vehicle ?? this.vehicle,
      premium: premium ?? this.premium,
      premiumPlan: premiumPlan ?? this.premiumPlan,
      premiumExpireAt: premiumExpireAt ?? this.premiumExpireAt,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      tripHistory: tripHistory ?? this.tripHistory,
      fuelData: fuelData ?? this.fuelData,
    );
  }
}

/// Session — chỉ lưu currentUserId, không lưu dữ liệu user.
class AppSession {
  const AppSession({this.currentUserId = ''});

  final String currentUserId;

  bool get isLoggedIn => currentUserId.isNotEmpty;

  factory AppSession.fromJson(Map<String, dynamic> json) {
    return AppSession(
      currentUserId: json['currentUserId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'currentUserId': currentUserId};

  AppSession copyWith({String? currentUserId}) {
    return AppSession(currentUserId: currentUserId ?? this.currentUserId);
  }
}

/// Root document data.json.
class UserDatabase {
  const UserDatabase({
    required this.users,
    this.session = const AppSession(),
  });

  final List<UserModel> users;
  final AppSession session;

  factory UserDatabase.empty() => const UserDatabase(users: []);

  factory UserDatabase.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'] as List<dynamic>? ?? [];

    var session = const AppSession();
    if (json['session'] is Map<String, dynamic>) {
      session = AppSession.fromJson(json['session'] as Map<String, dynamic>);
    } else if (json['currentUser'] is Map<String, dynamic>) {
      final legacy = json['currentUser'] as Map<String, dynamic>;
      session = AppSession(currentUserId: legacy['id'] as String? ?? '');
    }

    return UserDatabase(
      users: rawUsers
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .where((u) => u.id.isNotEmpty && u.email.isNotEmpty)
          .toList(),
      session: session,
    );
  }

  Map<String, dynamic> toJson() => {
        'users': users.map((u) => u.toJson()).toList(),
        'session': session.toJson(),
      };

  UserDatabase copyWith({
    List<UserModel>? users,
    AppSession? session,
    bool clearSession = false,
  }) {
    return UserDatabase(
      users: users ?? this.users,
      session: clearSession ? const AppSession() : (session ?? this.session),
    );
  }
}

/// Kết quả thao tác auth.
class AuthResult {
  const AuthResult({required this.success, this.message, this.user});

  final bool success;
  final String? message;
  final UserModel? user;

  static const ok = AuthResult(success: true);
}
