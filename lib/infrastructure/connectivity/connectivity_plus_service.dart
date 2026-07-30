import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

/// Production [ConnectivityService] backed by the local `connectivity_plus`
/// platform sensor. A `checkConnectivity` / stream error degrades the state
/// to [ConnectivityState.offline] rather than faking a connection.
final class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    // connectivity_plus -> `nm` -> D-Bus can fail asynchronously during init
    // (e.g. headless Linux with no NetworkManager throws
    // DBusServiceUnknownException from an internal unawaited `connect()`,
    // which the stream's onError can't capture). Zone-guard the whole init so
    // this degrades to offline instead of crashing the host.
    runZonedGuarded(_init, _degradeToOffline);
  }

  void _init() {
    unawaited(_seed());
    _changes = _connectivity.onConnectivityChanged.listen(
      _apply,
      onError: (_) => _publish(ConnectivityState.offline),
    );
  }

  void _degradeToOffline(Object _, StackTrace _) {
    _publish(ConnectivityState.offline);
  }

  final Connectivity _connectivity;

  // Optimistic initial seed so we don't flash an offline banner for a frame
  // on a connected launch; the first checkConnectivity corrects this.
  ConnectivityState _current = ConnectivityState.online;

  final StreamController<ConnectivityState> _controller =
      StreamController<ConnectivityState>.broadcast();
  // App-lifetime singleton; the lint can't trace the cross-method cancel.
  // ignore: cancel_subscriptions
  StreamSubscription<List<ConnectivityResult>>? _changes;
  bool _disposed = false;

  @override
  ConnectivityState get current => _current;

  @override
  Stream<ConnectivityState> get states {
    // Synchronous subscription (not an async* that yields-then-subscribes)
    // closes the race where an event between seed and subscribe is lost.
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
      // dispose must release listeners synchronously.
      unawaited(changes.cancel());
    }
    unawaited(_controller.close());
  }
}
