import 'package:shared_preferences/shared_preferences.dart';

/// Small synchronous-read preference store (sound, haptics, age band…).
abstract class SettingsStore {
  String? getString(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, {required bool value});
  Future<void> remove(String key);
}

class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsSettingsStore> load() async =>
      PrefsSettingsStore(await SharedPreferences.getInstance());

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  @override
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, Object>? initial]) : _data = {...?initial};

  final Map<String, Object> _data;

  @override
  String? getString(String key) => _data[key] as String?;
  @override
  bool? getBool(String key) => _data[key] as bool?;
  @override
  Future<void> setString(String key, String value) async => _data[key] = value;
  @override
  Future<void> setBool(String key, {required bool value}) async =>
      _data[key] = value;
  @override
  Future<void> remove(String key) async => _data.remove(key);
}
