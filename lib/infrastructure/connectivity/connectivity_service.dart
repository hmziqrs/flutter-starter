import 'package:starter/features/connectivity/connectivity_state.dart';

/// Cross-feature connectivity sensor port.
///
/// Built once here and shared (C4: do not multiply backends) — the connectivity
/// banner reads it today, and the future offline-cache will read this same port
/// rather than wiring a second sensor.
///
/// Unlike the settings store port, this is a *sensor* port: it publishes a
/// stream of connectivity transitions plus a synchronous snapshot of the latest
/// known state. It is backend-free by design — the production adapter is the
/// local `connectivity_plus` platform sensor, with no network round-trip and no
/// result ever faked. A sensor failure degrades honestly to
/// [ConnectivityState.offline] rather than throwing into the UI.
abstract interface class ConnectivityService {
  /// The live stream of connectivity transitions.
  ///
  /// Emits the cached [current] state to every new listener before any platform
  /// change arrives, so a cold read never resolves to "unknown".
  Stream<ConnectivityState> get states;

  /// The latest known connectivity state. Used as the synchronous seed for
  /// [states] consumers.
  ConnectivityState get current;

  /// Re-reads platform connectivity and re-emits on [states] if it changed.
  ///
  /// Called on the `resumed` lifecycle edge (see `connectivity_controller.dart`)
  /// so a device that changed networks while backgrounded re-syncs immediately.
  /// Never throws: an unreadable sensor degrades to [ConnectivityState.offline].
  Future<void> refresh();

  /// Releases platform subscriptions.
  ///
  /// The app-scope instance lives for the process, so this is primarily
  /// exercised by tests and an explicit teardown path.
  void dispose();
}
