import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/haptics/device_haptic_service.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/infrastructure/haptics/noop_haptic_service.dart';

/// The expected `HapticFeedbackType` argument string each [HapticKind] must
/// forward over the `HapticFeedback.vibrate` platform channel. Covering every
/// kind asserts the device adapter's switch is exhaustive and one-to-one —
/// adding a kind without a branch is a compile error, and remapping one is a
/// test failure.
const _expectedChannelArgs = <HapticKind, String>{
  HapticKind.selection: 'HapticFeedbackType.selectionClick',
  HapticKind.impactLight: 'HapticFeedbackType.lightImpact',
  HapticKind.impactMedium: 'HapticFeedbackType.mediumImpact',
  HapticKind.impactHeavy: 'HapticFeedbackType.heavyImpact',
  HapticKind.notificationSuccess: 'HapticFeedbackType.successNotification',
  HapticKind.notificationWarning: 'HapticFeedbackType.warningNotification',
  HapticKind.notificationError: 'HapticFeedbackType.errorNotification',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? lastChannelArgs;
  var failNextPlatformCall = false;

  setUp(() {
    lastChannelArgs = null;
    failNextPlatformCall = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          if (failNextPlatformCall) {
            throw PlatformException(code: 'unavailable');
          }
          lastChannelArgs = call.arguments as String?;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  group('DeviceHapticService', () {
    test('is const-constructible (stateless production adapter)', () {
      const DeviceHapticService();
    });

    for (final entry in _expectedChannelArgs.entries) {
      final kind = entry.key;
      final expected = entry.value;
      test('delegates $kind one-to-one to HapticFeedback ($expected)', () async {
        await const DeviceHapticService().trigger(kind);

        expect(lastChannelArgs, expected);
      });
    }

    test('covers every HapticKind in the mapping table', () {
      // Guard against a future kind landing without a channel-arg expectation.
      expect(_expectedChannelArgs.keys.toSet(), HapticKind.values.toSet());
    });

    test('wraps a platform error in HapticServiceException', () async {
      failNextPlatformCall = true;

      await expectLater(
        const DeviceHapticService().trigger(HapticKind.selection),
        throwsA(
          isA<HapticServiceException>()
              .having((error) => error.operation, 'operation', 'trigger')
              .having((error) => error.kind, 'kind', HapticKind.selection),
        ),
      );
    });
  });

  group('NoopHapticService', () {
    test('records the last kind, call count, and call order; fires nothing', () async {
      final noop = NoopHapticService();

      await noop.trigger(HapticKind.selection);
      await noop.trigger(HapticKind.notificationSuccess);
      await noop.trigger(HapticKind.impactHeavy);

      expect(noop.lastKind, HapticKind.impactHeavy);
      expect(noop.callCount, 3);
      expect(noop.calls, <HapticKind>[
        HapticKind.selection,
        HapticKind.notificationSuccess,
        HapticKind.impactHeavy,
      ]);
      // Hermeticity: the noop never reaches the platform channel.
      expect(lastChannelArgs, isNull);
    });

    test('starts empty', () {
      final noop = NoopHapticService();

      expect(noop.lastKind, isNull);
      expect(noop.callCount, 0);
      expect(noop.calls, isEmpty);
    });

    test('calls view is unmodifiable', () async {
      final noop = NoopHapticService();
      await noop.trigger(HapticKind.selection);

      expect(() => noop.calls.add(HapticKind.impactLight), throwsUnsupportedError);
    });
  });

  group('HapticServiceException', () {
    test('renders the operation and kind name', () {
      const error = HapticServiceException(
        operation: 'trigger',
        kind: HapticKind.impactHeavy,
      );

      expect(error.toString(), 'HapticServiceException: trigger failed for impactHeavy');
    });

    test('carries the typed kind', () {
      const error = HapticServiceException(
        operation: 'trigger',
        kind: HapticKind.notificationError,
      );

      expect(error.kind, HapticKind.notificationError);
      expect(error.operation, 'trigger');
    });
  });

  group('HapticKind', () {
    test('exposes exactly the seven canonical kinds', () {
      expect(HapticKind.values, hasLength(7));
      expect(HapticKind.values, containsAll(_expectedChannelArgs.keys));
    });
  });
}
