import 'package:starter/features/settings/settings_store.dart';

final class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore({Map<String, String>? seed}) : _values = {...?seed};

  final Map<String, String> _values;
  bool failReads = false;
  bool failWrites = false;

  Map<String, String> get snapshot => Map.unmodifiable(_values);

  @override
  Future<String?> readString(String key) async {
    if (failReads) {
      throw SettingsStoreException(operation: 'read', key: key);
    }
    return _values[key];
  }

  @override
  Future<void> remove(String key) async {
    if (failWrites) {
      throw SettingsStoreException(operation: 'remove', key: key);
    }
    _values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    if (failWrites) {
      throw SettingsStoreException(operation: 'write', key: key);
    }
    _values[key] = value;
  }
}
