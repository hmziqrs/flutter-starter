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

/// Whether the connectivity banner currently occupies space in the shell.
///
/// Shared by the ConnectivityBanner widget and the shell's banner host so both agree on
/// a single visibility rule.
final connectivityBannerVisibleProvider = Provider<bool>((ref) {
  final state = ref.watch(connectivityStatusProvider).value;
  return state != null && state.isDegraded;
});
