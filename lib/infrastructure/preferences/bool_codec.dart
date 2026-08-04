import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Boolean codec for the settings and secure stores.
///
/// Bools are persisted as the literal string `'true'`; the `false` state is
/// represented by REMOVING the key (so the default, on a missing key, is
/// `false`). This mirrors the hand-rolled encode/decode that previously lived
/// inline at every call site (see `SettingsRepository.save`/`load`).
///
/// Normal (default) semantics:
///   writeBool(value: true)  -> writeString('true')
///   writeBool(value: false) -> remove(key)
///   readBool                -> readString(key) == 'true'   (absent => false)
///
/// A few settings are INVERTED (default-on, e.g. haptics): the persisted
/// sentinel is `'false'` and a missing key means `true`. For those, pass
/// `invert: true`:
///   writeBool(value: true,  invert: true) -> remove(key)
///   writeBool(value: false, invert: true) -> writeString('false')
///   readBool(invert: true)                -> readString(key) != 'false'  (absent => true)
extension BoolCodecSettingsStore on SettingsStore {
  Future<bool> readBool(String key, {bool invert = false}) async {
    final value = await readString(key);
    return invert ? value != 'false' : value == 'true';
  }

  Future<void> writeBool(String key, {required bool value, bool invert = false}) async {
    if (invert) {
      // Inverted storage: the disabled state is persisted as 'false'; the
      // enabled state removes the key so the default-on value is restored.
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

/// Boolean codec for [SecureStore]. Same semantics as [BoolCodecSettingsStore]
/// but against the secure store's `read`/`write`/`delete` methods.
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
