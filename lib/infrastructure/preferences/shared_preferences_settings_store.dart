import 'package:shared_preferences/shared_preferences.dart';
import 'package:starter/features/settings/settings_store.dart';

final class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) async {
    try {
      return await _preferences.getString(key);
    } on Object {
      throw SettingsStoreException(operation: 'read', key: key);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _preferences.remove(key);
    } on Object {
      throw SettingsStoreException(operation: 'remove', key: key);
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      await _preferences.setString(key, value);
    } on Object {
      throw SettingsStoreException(operation: 'write', key: key);
    }
  }
}
