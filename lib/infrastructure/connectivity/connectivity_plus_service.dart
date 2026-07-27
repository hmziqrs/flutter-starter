import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

/// Production [ConnectivityService] backed by the local `connectivity_plus`
/// platform sensor.
///
/// Constructed once in `AppDependencies.production` and overridden at the App
/// `ProviderScope`. No widget reads `connectivity_plus` directly — every read
/// goes through the port, which is what keeps dev-gallery previews and tests
/// hermetic (a fake stream, no platform plugin).
///
/// The sensor never fakes a result: a `checkConnectivity` / stream error is
/// caught and degrades the state to [ConnectivityState.offline], surfacing the
/// banner honestly instead of claiming a connection that may not exist.
final class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    unawaited(_seed());
    _changes = _connectivity.onConnectivityChanged.listen(
      _apply,
      onError: (_) => _publish(ConnectivityState.offline),
    );
  }

  final Connectivity _connectivity;

  // Optimistic initial seed: the sensor has not reported yet, so we do not flash
  // an offline banner for a frame on a connected launch. The first
  // checkConnectivity result corrects this within milliseconds.
  ConnectivityState _current = ConnectivityState.online;

  final StreamController<ConnectivityState> _controller =
      StreamController<ConnectivityState>.broadcast();
  // Assigned in the constructor and cancelled in [dispose]; this is an
  // app-lifetime singleton, so the lint cannot trace the cross-method cancel.
  // ignore: cancel_subscriptions
  StreamSubscription<List<ConnectivityResult>>? _changes;
  bool _disposed = false;

  @override
  ConnectivityState get current => _current;

  @override
  Stream<ConnectivityState> get states {
    // Hand each new listener the cached snapshot, then forward live events.
    // Subscribing to the broadcast controller synchronously (rather than via an
    // `async*` that yields-then-subscribes) closes the race where a platform
    // event fired between the seed and the subscription would be lost.
    final outgoing = StreamController<ConnectivityState>();
    void forward(ConnectivityState state) {
      if (!outgoing.isClosed) {
        outgoing.add(state);
      }
    }

    final subscription = _controller.stream.listen(forward);
    outgoing
      ..add(_current)
      ..onCancel = () {
        unawaited(subscription.cancel());
        unawaited(outgoing.close());
      };
    return outgoing.stream;
  }

  @override
  Future<void> refresh() => _seed();

  Future<void> _seed() async {
    List<ConnectivityResult> results;
    try {
      results = await _connectivity.checkConnectivity();
    } on Object {
      // The sensor could not be read. Be honest: assume offline so the banner
      // surfaces and downstream actions show `common.notConnected` rather than
      // silently assuming a link.
      _publish(ConnectivityState.offline);
      return;
    }
    _publish(ConnectivityState.fromResults(results));
  }

  void _apply(List<ConnectivityResult> results) {
    _publish(ConnectivityState.fromResults(results));
  }

  void _publish(ConnectivityState next) {
    if (_disposed || next == _current) {
      return;
    }
    _current = next;
    _controller.add(next);
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final changes = _changes;
    _changes = null;
    if (changes != null) {
      // StreamSubscription.cancel returns a Future we deliberately do not
      // await: dispose must release listeners synchronously.
      unawaited(changes.cancel());
    }
    unawaited(_controller.close());
  }
}
