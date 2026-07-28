import 'package:flutter/foundation.dart';

/// Read-only diagnostic descriptor for the OS-backed secret store in use on
/// the host platform. Surfaced on the development `DiagnosticsPage`; never
/// gates a code path or a navigation decision.
enum SecureStoreBackend {
  keychain,
  keystore,
  dpapi,
  libsecret,
  web,
  unsupported,
}

/// Resolves the [SecureStoreBackend] the production adapter
/// (`FlutterSecureStorageStore`) targets for the current platform.
///
/// This is a platform-derived descriptor, not a claim about stored data: on
/// every supported platform the production adapter writes to exactly this
/// backend. Web/desktop fall back to the plugin's supported backend or surface
/// [SecureStoreBackend.unsupported] rather than silently falling through to
/// `SharedPreferences`.
SecureStoreBackend resolveSecureStoreBackend() {
  if (kIsWeb) {
    return SecureStoreBackend.web;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => SecureStoreBackend.keychain,
    TargetPlatform.android => SecureStoreBackend.keystore,
    TargetPlatform.windows => SecureStoreBackend.dpapi,
    TargetPlatform.linux => SecureStoreBackend.libsecret,
    TargetPlatform.fuchsia => SecureStoreBackend.unsupported,
  };
}
