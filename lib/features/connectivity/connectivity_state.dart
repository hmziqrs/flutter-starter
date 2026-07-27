import 'package:connectivity_plus/connectivity_plus.dart';

/// App-owned connectivity status, abstracted away from the raw radio transports
/// reported by `connectivity_plus`.
///
/// Both the connectivity banner and the future offline-cache switch on this
/// enum — never on the plugin's `ConnectivityResult` types — so the surface
/// stays stable as `connectivity_plus` grows new transports. Each new
/// `ConnectivityResult` value is a compile error in [fromResult] until it is
/// deliberately classified here.
enum ConnectivityState {
  /// A reliable IP link is available (Wi-Fi, ethernet, or mobile data).
  online,

  /// No network link is available.
  offline,

  /// A constrained, tunneled, or unknown link is available. Actions may work but
  /// are not guaranteed — satellite ("highly constrained" per the plugin docs),
  /// bluetooth tethering, VPN, and unknown transports.
  limited,
  ;

  /// Maps a single radio transport to a connectivity state.
  ///
  /// Exhaustive over every `ConnectivityResult`: adding a new transport to the
  /// plugin is a compile error here until it is classified. Wi-Fi, ethernet, and
  /// mobile are [online]; satellite, bluetooth, VPN, and unknown transports are
  /// [limited]; the explicit no-link sentinel (`none`) is [offline].
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

  /// Folds the plugin's list of active transports into one connectivity state.
  ///
  /// `connectivity_plus` reports a `List<ConnectivityResult>` whose only
  /// guaranteed shape is "never empty; `[none]` means fully offline". We reduce
  /// by precedence: any reliable link wins ([online]); otherwise a constrained
  /// link surfaces [limited]; otherwise the device is [offline].
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

  /// Whether the persistent banner should surface a row for this state.
  ///
  /// Only degraded states (`offline`/`limited`) show the banner; [online] is the
  /// quiet default and is announced only by the transient "back online" toast on
  /// the recovery edge.
  bool get isDegraded => this == ConnectivityState.offline || this == ConnectivityState.limited;
}
