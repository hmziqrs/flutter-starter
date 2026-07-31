import 'dart:async';

import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

final class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({
    ConnectivityState initial = ConnectivityState.online,
  }) : _current = initial,
       _controller = StreamController<ConnectivityState>.broadcast(sync: true);

  final StreamController<ConnectivityState> _controller;
  ConnectivityState _current;

  int refreshCount = 0;

  bool disposed = false;

  @override
  ConnectivityState get current => _current;

  @override
  Stream<ConnectivityState> get states {
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
    unawaited(_controller.close());
  }
}
