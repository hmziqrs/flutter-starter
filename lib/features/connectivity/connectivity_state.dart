import 'package:connectivity_plus/connectivity_plus.dart';

/// App-owned connectivity status, abstracted away from the raw radio
/// transports reported by `connectivity_plus`. Consumers switch on this enum,
/// never on the plugin's `ConnectivityResult` types, so the surface stays
/// stable as the plugin grows new transports.
enum ConnectivityState {
  /// A reliable IP link is available (Wi-Fi, ethernet, or mobile data).
  online,

  /// No network link is available.
  offline,

  /// A constrained, tunneled, or unknown link is available. Actions may work
  /// but are not guaranteed — satellite, bluetooth tethering, VPN, and
  /// unknown transports.
  limited,
  ;

  /// Maps a single radio transport to a connectivity state. Exhaustive over
  /// every `ConnectivityResult`, so a new plugin transport is a compile error
  /// here until classified.
  static ConnectivityState fromResult(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi => ConnectivityState.online,
      ConnectivityResult.ethernet => ConnectivityState.online,
      ConnectivityResult.mobile => ConnectivityState.online,
      ConnectivityResult.none => ConnectivityState.offline,
      ConnectivityResult.bluetooth => ConnectivityState.limited,
      ConnectivityResult.vpn => ConnectivityState.limited,
      ConnectivityResult.satellite => ConnectivityState.limited,
      ConnectivityResult.other => ConnectivityState.limited,
    };
  }

  /// Folds the plugin's list of active transports into one connectivity
  /// state by precedence: any reliable link wins ([online]); otherwise a
  /// constrained link surfaces [limited]; otherwise the device is [offline].
  static ConnectivityState fromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityState.offline;
    }
    var hasLimited = false;
    for (final result in results) {
      final mapped = fromResult(result);
      if (mapped == ConnectivityState.online) {
        return ConnectivityState.online;
      }
      if (mapped == ConnectivityState.limited) {
        hasLimited = true;
      }
    }
    return hasLimited ? ConnectivityState.limited : ConnectivityState.offline;
  }

  /// Whether the persistent banner should surface a row for this state. Only
  /// degraded states (`offline`/`limited`) show the banner; [online] is
  /// announced only by the transient "back online" toast.
  bool get isDegraded => this == ConnectivityState.offline || this == ConnectivityState.limited;
}
