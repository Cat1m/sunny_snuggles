import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  PrefsService(this._prefs);
  final SharedPreferences _prefs;

  static Future<PrefsService> create() async {
    final p = await SharedPreferences.getInstance();
    return PrefsService(p);
  }

  Future<bool> setJson(String key, String json) async =>
      _prefs.setString(key, json);
  String? getJson(String key) => _prefs.getString(key);
  Future<bool> remove(String key) async => _prefs.remove(key);
}
