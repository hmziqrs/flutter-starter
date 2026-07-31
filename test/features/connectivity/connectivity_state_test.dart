import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';

void main() {
  group('ConnectivityState.fromResult', () {
    final cases = <(ConnectivityResult, ConnectivityState)>[
      (ConnectivityResult.bluetooth, ConnectivityState.limited),
      (ConnectivityResult.wifi, ConnectivityState.online),
      (ConnectivityResult.ethernet, ConnectivityState.online),
      (ConnectivityResult.mobile, ConnectivityState.online),
      (ConnectivityResult.none, ConnectivityState.offline),
      (ConnectivityResult.vpn, ConnectivityState.limited),
      (ConnectivityResult.satellite, ConnectivityState.limited),
      (ConnectivityResult.other, ConnectivityState.limited),
    ];

    for (final (result, expected) in cases) {
      test('maps $result to $expected', () {
        expect(ConnectivityState.fromResult(result), expected);
      });
    }

    test('is exhaustive over every ConnectivityResult value', () {
      expect(ConnectivityResult.values.length, 8);
      expect(
        ConnectivityResult.values.map(ConnectivityState.fromResult).toSet(),
        isNotEmpty,
      );
    });
  });

  group('ConnectivityState.fromResults', () {
    final foldCases = <(List<ConnectivityResult>, ConnectivityState)>[
      (<ConnectivityResult>[], ConnectivityState.offline),
      ([ConnectivityResult.none], ConnectivityState.offline),
      ([ConnectivityResult.wifi], ConnectivityState.online),
      ([ConnectivityResult.ethernet], ConnectivityState.online),
      ([ConnectivityResult.mobile], ConnectivityState.online),
      ([ConnectivityResult.none, ConnectivityResult.mobile], ConnectivityState.online),
      ([ConnectivityResult.mobile, ConnectivityResult.satellite], ConnectivityState.online),
      ([ConnectivityResult.satellite], ConnectivityState.limited),
      ([ConnectivityResult.bluetooth], ConnectivityState.limited),
      ([ConnectivityResult.vpn], ConnectivityState.limited),
      ([ConnectivityResult.vpn, ConnectivityResult.none], ConnectivityState.limited),
      ([ConnectivityResult.other], ConnectivityState.limited),
    ];

    for (final (results, expected) in foldCases) {
      test('folds $results to $expected', () {
        expect(ConnectivityState.fromResults(results), expected);
      });
    }
  });

  group('ConnectivityState.isDegraded', () {
    test('only offline and limited are degraded', () {
      expect(ConnectivityState.offline.isDegraded, isTrue);
      expect(ConnectivityState.limited.isDegraded, isTrue);
      expect(ConnectivityState.online.isDegraded, isFalse);
    });
  });
}
