import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

final secureStoreProvider = Provider<SecureStore>(
  (ref) => throw StateError('SecureStore must be overridden at the composition root.'),
);
