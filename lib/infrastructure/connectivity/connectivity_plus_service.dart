import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

final class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity, AppLogger? logger})
    : _connectivity = connectivity ?? Connectivity(),
      _logger = logger ?? AppLogger.bootstrap() {
    runZonedGuarded(_init, _degradeToOffline);
  }

  void _init() {
    unawaited(_seed());
    _changes = _connectivity.onConnectivityChanged.listen(
      _apply,
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning(
          'connectivity.stream_error',
          error: error,
          stackTrace: stackTrace,
        );
        _publish(ConnectivityState.offline);
      },
    );
  }

  void _degradeToOffline(Object error, StackTrace stackTrace) {
    _logger.warning('connectivity.zone_error', error: error, stackTrace: stackTrace);
    _publish(ConnectivityState.offline);
  }

  final Connectivity _connectivity;

  final AppLogger _logger;

  ConnectivityState _current = ConnectivityState.online;

  final StreamController<ConnectivityState> _controller =
      StreamController<ConnectivityState>.broadcast();
  // ignore: cancel_subscriptions, app-lifetime singleton
  StreamSubscription<List<ConnectivityResult>>? _changes;
  bool _disposed = false;

  @override
  ConnectivityState get current => _current;

  @override
  Stream<ConnectivityState> get states {
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
    } on Object catch (error, stackTrace) {
      _logger.warning('connectivity.seed_failed', error: error, stackTrace: stackTrace);
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
      unawaited(changes.cancel());
    }
    unawaited(_controller.close());
  }
}
