import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value store for drafts, cached screens and the sync outbox.
/// Overridden in main() with an instance backed by SharedPreferences.
final localStoreProvider = Provider<LocalStore>((ref) => throw UnimplementedError('override in main'));

class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  Object? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getMap(String key) {
    final v = getJson(key);
    return v is Map<String, dynamic> ? v : null;
  }

  List<dynamic>? getList(String key) {
    final v = getJson(key);
    return v is List ? v : null;
  }

  Future<void> setJson(String key, Object? value) => _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);

  Iterable<String> keysWithPrefix(String prefix) => _prefs.getKeys().where((k) => k.startsWith(prefix));

  /// Wipe everything tied to the signed-in user (drafts, cache, outbox).
  Future<void> clearUserData() async {
    for (final k in _prefs.getKeys().toList()) {
      if (!k.startsWith('pref:')) await _prefs.remove(k);
    }
  }
}
