import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveJson(String key, Object value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, jsonEncode(value));
  }

  static Future<dynamic> loadJson(String key, {dynamic fallback}) async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(key);
    if (s == null) return fallback;
    try { return jsonDecode(s); } catch (_) { return fallback; }
  }

  static Future<void> remove(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(key);
  }
}
