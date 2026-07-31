import 'package:starter/features/connectivity/connectivity_state.dart';

abstract interface class ConnectivityService {
  Stream<ConnectivityState> get states;

  ConnectivityState get current;

  Future<void> refresh();

  void dispose();
}
