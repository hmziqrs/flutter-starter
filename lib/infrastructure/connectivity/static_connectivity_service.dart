import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

/// Reports a fixed state without touching platform channels, for in-memory
/// compositions, gallery previews, and integration hosts without a network
/// stack.
final class StaticConnectivityService implements ConnectivityService {
  const StaticConnectivityService({this.state = ConnectivityState.online});

  final ConnectivityState state;

  @override
  ConnectivityState get current => state;

  @override
  Stream<ConnectivityState> get states => Stream<ConnectivityState>.value(state);

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {}
}
