import 'dart:async';

import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

/// Test-only [ConnectivityService] backed by a [StreamController].
///
/// Mirrors `InMemorySettingsStore` (no Mocktail): tests drive deterministic
/// transitions through [emit] and assert the controller/banner react. Never
/// used in production code.
final class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({
    ConnectivityState initial = ConnectivityState.online,
  }) : _current = initial,
       _controller = StreamController<ConnectivityState>.broadcast(sync: true);

  // Synchronous so test transitions are delivered deterministically within a
  // single `pump`, without depending on microtask interleaving.
  final StreamController<ConnectivityState> _controller;
  ConnectivityState _current;

  /// Number of times [refresh] was called. Resume-refresh tests assert this to
  /// verify the `resumed` lifecycle edge re-arms the sensor.
  int refreshCount = 0;

  bool disposed = false;

  @override
  ConnectivityState get current => _current;

  @override
  Stream<ConnectivityState> get states {
    // Seed the cached snapshot for the new listener, then forward live events
    // from the broadcast controller. A single-subscription outgoing controller
    // buffers the seed until the listener attaches.
    final outgoing = StreamController<ConnectivityState>(sync: true);
    final subscription = _controller.stream.listen(outgoing.add);
    outgoing
      ..add(_current)
      ..onCancel = () {
        unawaited(subscription.cancel());
        unawaited(outgoing.close());
      };
    return outgoing.stream;
  }

  /// Drives a transition: updates [current] and emits on [states].
  void emit(ConnectivityState state) {
    _current = state;
    _controller.add(state);
  }

  @override
  Future<void> refresh() async {
    refreshCount += 1;
  }

  @override
  void dispose() {
    disposed = true;
    // StreamController.close returns a Future; dispose is synchronous.
    unawaited(_controller.close());
  }
}
