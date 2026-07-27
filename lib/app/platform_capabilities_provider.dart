import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

final platformCapabilitiesProvider = Provider<PlatformCapabilities>((ref) {
  throw StateError('platformCapabilitiesProvider must be overridden by App.');
});
