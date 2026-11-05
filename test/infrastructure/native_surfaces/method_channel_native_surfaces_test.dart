import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/native_surfaces/native_surfaces_port.dart';
import 'package:starter/features/native_surfaces/surface_snapshot.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/native_surfaces/method_channel_native_surfaces.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelNativeSurfaces.channelName);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final snapshot = SurfaceSnapshot(
    title: 'Starter',
    subtitle: 'Build running',
    updatedAt: DateTime.utc(2026, 11, 5),
    value: '72%',
    progress: 1.4,
    status: SurfaceStatus.active,
    actions: const [SurfaceAction(label: 'Pricing', route: '/pricing')],
  );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('publish sends the documented JSON, with progress held to 0 to 1', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    await MethodChannelNativeSurfaces(logger: AppLogger.bootstrap()).publish(snapshot);

    expect(received!.method, 'publish');
    expect(jsonDecode(received!.arguments as String), <String, Object?>{
      'schema': 1,
      'title': 'Starter',
      'subtitle': 'Build running',
      'value': '72%',
      'valueLabel': null,
      'progress': 1.0,
      'status': 'active',
      'updatedAt': '2026-11-05T00:00:00.000Z',
      'route': '/',
      'actions': [
        {'label': 'Pricing', 'route': '/pricing'},
      ],
    });
  });

  test('a platform with no implementation is a quiet no-op', () async {
    final surfaces = MethodChannelNativeSurfaces(logger: AppLogger.bootstrap());

    await surfaces.publish(snapshot);
    await surfaces.endLive();

    expect(await surfaces.startLive(snapshot), isFalse);
    expect(await surfaces.takeLaunchRoute(), isNull);
  });

  test('a native error does not reach the caller', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    final surfaces = MethodChannelNativeSurfaces(logger: AppLogger.bootstrap());

    await surfaces.publish(snapshot);
    expect(await surfaces.startLive(snapshot), isFalse);
  });

  test('routes requested by native code reach the stream', () async {
    final surfaces = MethodChannelNativeSurfaces(logger: AppLogger.bootstrap());
    final next = surfaces.routeRequests.first;

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('openRoute', '/pricing')),
      (_) {},
    );

    expect(await next, '/pricing');
  });

  test('only shell routes may be opened from outside the app', () {
    expect(isOpenableSurfaceRoute('/'), isTrue);
    expect(isOpenableSurfaceRoute('/pricing'), isTrue);
    expect(isOpenableSurfaceRoute('/settings'), isTrue);
    expect(isOpenableSurfaceRoute('/force-update'), isFalse);
    expect(isOpenableSurfaceRoute('/dev/diagnostics'), isFalse);
    expect(isOpenableSurfaceRoute('https://example.com'), isFalse);
  });
}
