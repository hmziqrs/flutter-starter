import 'package:shared_preferences/shared_preferences.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/shared/async/storage_guard.dart';

final class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static Never _fail(Object error, String operation, String key) =>
      throw SettingsStoreException(operation: operation, key: key);

  @override
  Future<String?> readString(String key) {
    return guardStorageOpAsync(
      operation: 'read',
      key: key,
      action: () => _preferences.getString(key),
      failure: _fail,
    );
  }

  @override
  Future<void> remove(String key) {
    return guardStorageOpAsync(
      operation: 'remove',
      key: key,
      action: () => _preferences.remove(key),
      failure: _fail,
    );
  }

  @override
  Future<void> writeString(String key, String value) {
    return guardStorageOpAsync(
      operation: 'write',
      key: key,
      action: () => _preferences.setString(key, value),
      failure: _fail,
    );
  }
}
