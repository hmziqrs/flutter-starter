import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityState {
  online,

  offline,

  limited,
  ;

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

  bool get isDegraded => this == ConnectivityState.offline || this == ConnectivityState.limited;
}
