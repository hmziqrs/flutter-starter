import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_plus_service.dart';

class _FakeConnectivityPlatform extends ConnectivityPlatform {
  _FakeConnectivityPlatform({
    List<ConnectivityResult> initial = const [ConnectivityResult.wifi],
  }) : checkResult = initial,
       _controller = StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> checkResult;
  Exception? checkError;
  final StreamController<List<ConnectivityResult>> _controller;

  void emit(List<ConnectivityResult> results) => _controller.add(results);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    final error = checkError;
    if (error != null) {
      throw error;
    }
    return checkResult;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;
}

void main() {
  late ConnectivityPlatform originalPlatform;

  setUp(() => originalPlatform = ConnectivityPlatform.instance);

  tearDown(() => ConnectivityPlatform.instance = originalPlatform);

  test('current resolves to the seed checkConnectivity result', () async {
    final fake = _FakeConnectivityPlatform(
      initial: const [
        ConnectivityResult.none,
      ],
    );
    ConnectivityPlatform.instance = fake;

    final service = ConnectivityPlusService();
    addTearDown(service.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(service.current, ConnectivityState.offline);
  });

  test('forwards onConnectivityChanged transitions through the fold', () async {
    final fake = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = fake;

    final service = ConnectivityPlusService();
    addTearDown(service.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(service.current, ConnectivityState.online);

    fake.emit([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    expect(service.current, ConnectivityState.offline);

    fake.emit([ConnectivityResult.bluetooth]);
    await Future<void>.delayed(Duration.zero);
    expect(service.current, ConnectivityState.limited);

    fake.emit([ConnectivityResult.mobile, ConnectivityResult.satellite]);
    await Future<void>.delayed(Duration.zero);
    expect(service.current, ConnectivityState.online);
  });

  test('refresh re-reads platform connectivity and re-publishes', () async {
    final fake = _FakeConnectivityPlatform(
      initial: const [
        ConnectivityResult.none,
      ],
    );
    ConnectivityPlatform.instance = fake;

    final service = ConnectivityPlusService();
    addTearDown(service.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(service.current, ConnectivityState.offline);

    fake.checkResult = [ConnectivityResult.wifi];
    await service.refresh();
    await Future<void>.delayed(Duration.zero);

    expect(service.current, ConnectivityState.online);
  });

  test('a checkConnectivity error degrades honestly to offline', () async {
    final fake = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = fake;

    final service = ConnectivityPlusService();
    addTearDown(service.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(service.current, ConnectivityState.online);

    fake.checkError = Exception('sensor unavailable');
    await service.refresh();
    await Future<void>.delayed(Duration.zero);

    expect(service.current, ConnectivityState.offline);
  });

  test('states seeds each listener with current before live events', () async {
    final fake = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = fake;

    final service = ConnectivityPlusService();
    addTearDown(service.dispose);
    await Future<void>.delayed(Duration.zero);

    final seen = <ConnectivityState>[];
    final subscription = service.states.listen(seen.add);
    addTearDown(subscription.cancel);

    await Future<void>.delayed(Duration.zero);

    expect(seen.first, ConnectivityState.online);
  });
}
