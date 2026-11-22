import 'package:shared_preferences/shared_preferences.dart';

/// A tiny key → text store for things kept on the farmer's own phone (the
/// cart and their contact details).
abstract class LocalStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// Keeps values on the device, so they survive the app being closed.
class PrefsStore implements LocalStore {
  PrefsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

/// Keeps values only while the app is running. Used in tests.
class MemoryStore implements LocalStore {
  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
