import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_tracker_app/features/auth/models/user_model.dart';

/// Đọc/ghi data.json — ưu tiên assets/data/data.json (debug) hoặc bản sao trong documents.
/// Trên Web: lưu JSON trong SharedPreferences (localStorage), không dùng dart:io.
class UserDataStore {
  static const assetPath = 'assets/data/data.json';
  static const projectRelativePath = 'assets/data/data.json';
  static const _webPrefsKey = 'fuel_tracker_user_database_v1';

  File? _cachedFile;
  UserDatabase _db = UserDatabase.empty();
  bool _ready = false;

  UserDatabase get database => _db;
  bool get isReady => _ready;

  /// Đường dẫn file JSON đang dùng (debug).
  String? get activeFilePath {
    if (kIsWeb) return 'web:localStorage/$_webPrefsKey';
    return _cachedFile?.path;
  }

  Future<void> ensureReady() async {
    if (_ready) return;
    try {
      if (kIsWeb) {
        await _ensureReadyWeb();
      } else {
        await _ensureReadyNative();
      }
      _ready = true;
    } catch (e, stack) {
      debugPrint('[UserDataStore.ensureReady] $e');
      debugPrint(stack.toString());
      _db = UserDatabase.empty();
      _ready = true;
    }
  }

  Future<void> _ensureReadyWeb() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_webPrefsKey);

    if (raw == null || raw.trim().isEmpty || !_hasDemoUsers(raw)) {
      raw = await _loadSeedString();
      await prefs.setString(_webPrefsKey, raw);
    }

    _db = _parseDatabase(raw);
    if (_db.users.isEmpty) {
      raw = await _loadSeedString();
      await prefs.setString(_webPrefsKey, raw);
      _db = _parseDatabase(raw);
    }
    debugPrint('[UserDataStore] web ready — ${_db.users.length} users');
  }

  Future<void> _ensureReadyNative() async {
    final file = await _resolveWritableFile();
    _cachedFile = file;
    if (!await file.exists()) {
      await _writeSeed(file);
    }
    await _loadFromFile(file);
    if (_db.users.isEmpty && await file.exists()) {
      await _writeSeed(file);
      await _loadFromFile(file);
    }
  }

  bool _hasDemoUsers(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final users = map['users'] as List<dynamic>? ?? [];
      return users.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  UserDatabase _parseDatabase(String raw) {
    try {
      if (raw.trim().isEmpty) return UserDatabase.empty();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserDatabase.fromJson(map);
    } catch (e) {
      debugPrint('[UserDataStore] parse error: $e');
      return UserDatabase.empty();
    }
  }

  Future<String> _loadSeedString() async {
    try {
      final seed = await rootBundle.loadString(assetPath);
      return _prettyJson(seed);
    } catch (e) {
      debugPrint('[UserDataStore] seed load failed: $e');
      return const JsonEncoder.withIndent('  ').convert(UserDatabase.empty().toJson());
    }
  }

  Future<File> _resolveWritableFile() async {
    // Chỉ dùng đường dẫn project trên desktop — mobile không ghi được assets/.
    if (!kIsWeb && _isDesktopHost()) {
      final projectFile = File(projectRelativePath);
      if (kDebugMode) {
        try {
          final parent = projectFile.parent;
          if (!await parent.exists()) {
            await parent.create(recursive: true);
          }
          if (!await projectFile.exists()) {
            await _writeSeed(projectFile);
          }
          return projectFile;
        } catch (e) {
          debugPrint('[UserDataStore] project path unavailable: $e');
        }
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${dir.path}/assets/data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return File('${dataDir.path}/data.json');
  }

  Future<void> _writeSeed(File file) async {
    try {
      final seed = await _loadSeedString();
      await file.writeAsString(seed);
    } catch (_) {
      final empty = UserDatabase.empty();
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
      );
    }
  }

  bool _isDesktopHost() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      debugPrint('[UserDataStore] prettyJson failed: $e');
      return raw;
    }
  }

  Future<void> _loadFromFile(File file) async {
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        _db = UserDatabase.empty();
        return;
      }
      final map = jsonDecode(content) as Map<String, dynamic>;
      _db = UserDatabase.fromJson(map);
    } catch (e, stack) {
      debugPrint('[UserDataStore] JSON parse/read error: $e');
      debugPrint(stack.toString());
      _db = UserDatabase.empty();
      try {
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(_db.toJson()),
        );
      } catch (writeErr) {
        debugPrint('[UserDataStore] failed to rewrite defaults: $writeErr');
      }
    }
  }

  Future<void> save() async {
    final json = const JsonEncoder.withIndent('  ').convert(_db.toJson());

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webPrefsKey, json);
      debugPrint('[UserDataStore] saved → web:localStorage/$_webPrefsKey');
      return;
    }

    final file = _cachedFile ?? await _resolveWritableFile();
    _cachedFile = file;
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsString(json);
    debugPrint('[UserDataStore] saved → ${file.path}');
  }

  Future<void> reload() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webPrefsKey);
      if (raw == null) return;
      _db = _parseDatabase(raw);
      return;
    }

    final file = _cachedFile;
    if (file == null || !await file.exists()) return;
    await _loadFromFile(file);
  }

  void replaceDatabase(UserDatabase db) => _db = db;
}
