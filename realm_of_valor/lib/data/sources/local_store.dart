import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
