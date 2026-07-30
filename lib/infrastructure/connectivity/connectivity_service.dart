import 'package:starter/features/connectivity/connectivity_state.dart';

/// Cross-feature connectivity sensor port, shared so the connectivity banner
/// and the offline-cache read the same port rather than each wiring a sensor.
///
/// A sensor port: publishes a stream of connectivity transitions plus a
/// synchronous snapshot of the latest known state. Backend-free — the
/// production adapter is the local `connectivity_plus` platform sensor. A
/// sensor failure degrades to [ConnectivityState.offline] rather than
/// throwing into the UI.
abstract interface class ConnectivityService {
  /// Emits the cached [current] state to every new listener before any
  /// platform change arrives, so a cold read never resolves to "unknown".
  Stream<ConnectivityState> get states;

  /// The latest known connectivity state; the synchronous seed for [states].
  ConnectivityState get current;

  /// Re-reads platform connectivity and re-emits on [states] if changed.
  /// Called on the `resumed` lifecycle edge. Never throws.
  Future<void> refresh();

  /// Releases platform subscriptions.
  void dispose();
}
