import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage._();

  static SharedPreferences? _preferences;

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    final SharedPreferences? preferences = _preferences;

    if (preferences == null) {
      throw StateError('AppStorage debe inicializarse antes de utilizarse.');
    }

    return preferences;
  }

  static Future<bool> saveString(String key, String value) {
    return _instance.setString(key, value);
  }

  static String? readString(String key) {
    return _instance.getString(key);
  }

  static Future<bool> saveBool(String key, bool value) {
    return _instance.setBool(key, value);
  }

  static bool? readBool(String key) {
    return _instance.getBool(key);
  }

  static Future<bool> saveInt(String key, int value) {
    return _instance.setInt(key, value);
  }

  static int? readInt(String key) {
    return _instance.getInt(key);
  }

  static Future<bool> saveDouble(String key, double value) {
    return _instance.setDouble(key, value);
  }

  static double? readDouble(String key) {
    return _instance.getDouble(key);
  }

  static Future<bool> saveStringList(String key, List<String> value) {
    return _instance.setStringList(key, value);
  }

  static List<String>? readStringList(String key) {
    return _instance.getStringList(key);
  }

  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }

  static Future<bool> remove(String key) {
    return _instance.remove(key);
  }

  static Future<bool> clear() {
    return _instance.clear();
  }
}
