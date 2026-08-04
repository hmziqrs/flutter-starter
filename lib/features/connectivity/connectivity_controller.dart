import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/shared/state/app_lifecycle_listener.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => throw StateError(
    'ConnectivityService must be overridden at the composition root.',
  ),
);

final connectivityStatusProvider = StreamProvider<ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  listenOnResume(ref, service.refresh);
  return service.states;
});
