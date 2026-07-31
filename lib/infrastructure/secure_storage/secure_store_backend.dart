import 'package:flutter/foundation.dart';

enum SecureStoreBackend {
  keychain,
  keystore,
  dpapi,
  libsecret,
  web,
  unsupported,
}

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
