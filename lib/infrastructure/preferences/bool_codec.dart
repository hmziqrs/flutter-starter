import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

extension BoolCodecSettingsStore on SettingsStore {
  Future<bool> readBool(String key, {bool invert = false}) async {
    final value = await readString(key);
    return invert ? value != 'false' : value == 'true';
  }

  Future<void> writeBool(String key, {required bool value, bool invert = false}) async {
    if (invert) {
      if (value) {
        await remove(key);
      } else {
        await writeString(key, 'false');
      }
    } else {
      if (value) {
        await writeString(key, 'true');
      } else {
        await remove(key);
      }
    }
  }
}

extension BoolCodecSecureStore on SecureStore {
  Future<bool> readBool(String key, {bool invert = false}) async {
    final value = await read(key);
    return invert ? value != 'false' : value == 'true';
  }

  Future<void> writeBool(String key, {required bool value, bool invert = false}) async {
    if (invert) {
      if (value) {
        await delete(key);
      } else {
        await write(key, 'false');
      }
    } else {
      if (value) {
        await write(key, 'true');
      } else {
        await delete(key);
      }
    }
  }
}
