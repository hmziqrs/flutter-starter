import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tvos/flutter_tvos.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/platform_capabilities_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const androidChannel = MethodChannel('starter/platform_capabilities');
  late TargetPlatform? previousTargetPlatform;

  setUp(() {
    previousTargetPlatform = debugDefaultTargetPlatformOverride;
    TvOSInfo.bindingsOverride = _FakeTvOsBindings(isTvOS: false);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = previousTargetPlatform;
    TvOSInfo.bindingsOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      androidChannel,
      null,
    );
  });

  test('redacted summary exposes classification but no tvOS device facts', () async {
    TvOSInfo.bindingsOverride = _FakeTvOsBindings(
      isTvOS: true,
      machineId: 'SECRET-MACHINE-ID',
      deviceModel: 'SECRET-DEVICE-MODEL',
    );

    final capabilities = await const PlatformCapabilitiesResolver().resolve();

    expect(
      capabilities,
      const PlatformCapabilities(
        platform: 'tvOS',
        isWeb: false,
        tvPlatform: AppTvPlatform.tvOS,
      ),
    );
    expect(
      capabilities.redactedSummary,
      'platform=tvOS, web=false, tv=tvOS',
    );
    expect(capabilities.redactedSummary, isNot(contains('SECRET-MACHINE-ID')));
    expect(
      capabilities.redactedSummary,
      isNot(contains('SECRET-DEVICE-MODEL')),
    );
  });

  for (final isTv in [false, true]) {
    test('Android channel maps isAndroidTv=$isTv without extra metadata', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var invocationCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        androidChannel,
        (call) async {
          invocationCount += 1;
          expect(call.method, 'isAndroidTv');
          expect(call.arguments, isNull);
          return isTv;
        },
      );

      final capabilities = await const PlatformCapabilitiesResolver().resolve();

      expect(invocationCount, 1);
      expect(capabilities.platform, 'android');
      expect(capabilities.isWeb, isFalse);
      expect(
        capabilities.tvPlatform,
        isTv ? AppTvPlatform.androidTv : AppTvPlatform.none,
      );
      expect(capabilities.isTelevision, isTv);
    });
  }

  test('non-Android platforms never invoke the Android capability channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      androidChannel,
      (_) async {
        fail('Non-Android resolution must not invoke the Android channel.');
      },
    );

    final capabilities = await const PlatformCapabilitiesResolver().resolve();

    expect(
      capabilities,
      const PlatformCapabilities(
        platform: 'linux',
        isWeb: false,
        tvPlatform: AppTvPlatform.none,
      ),
    );
  });

  test('Android channel timeout prevents capability detection from hanging startup', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final neverCompletes = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      androidChannel,
      (_) => neverCompletes.future,
    );

    final stopwatch = Stopwatch()..start();
    await expectLater(
      const PlatformCapabilitiesResolver(
        androidChannel,
        Duration(milliseconds: 10),
      ).resolve(),
      throwsA(isA<TimeoutException>()),
    );

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('capability values compare by classification', () {
    const first = PlatformCapabilities(
      platform: 'android',
      isWeb: false,
      tvPlatform: AppTvPlatform.androidTv,
    );
    const same = PlatformCapabilities(
      platform: 'android',
      isWeb: false,
      tvPlatform: AppTvPlatform.androidTv,
    );
    const nearField = PlatformCapabilities.nonTelevision(
      platform: 'android',
    );

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(nearField));
    expect(first.isTelevision, isTrue);
    expect(nearField.isTelevision, isFalse);
  });
}

final class _FakeTvOsBindings extends TvOSNativeBindings {
  _FakeTvOsBindings({
    required this.isTvOS,
    this.machineId = '',
    this.deviceModel = '',
  }) : super.forTesting();

  @override
  final bool isTvOS;

  @override
  final String machineId;

  @override
  final String deviceModel;
}
