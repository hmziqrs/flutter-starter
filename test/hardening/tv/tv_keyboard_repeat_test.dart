import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/keyboard/app_keyboard_host.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';

import 'tv_test_harness.dart';

void main() {
  const activationKeys = <LogicalKeyboardKey>[
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.gameButtonA,
  ];

  for (final policy in const [
    AppInteractionPolicy.remote,
    AppInteractionPolicy.hybridRemote,
  ]) {
    testWidgets('${policy.name} suppresses activation repeats after one invocation', (
      tester,
    ) async {
      configureTvTestView(tester);
      final invocations = <LogicalKeyboardKey, int>{};

      await pumpTvKeyboardHarness(
        tester,
        interactionPolicy: policy,
        child: AppKeyboardHost(
          interactionPolicy: policy,
          bindings: [
            for (final key in activationKeys)
              AppKeyboardBinding(
                activator: SingleActivator(key),
                onInvoke: () {
                  invocations.update(
                    key,
                    (count) => count + 1,
                    ifAbsent: () => 1,
                  );
                  return true;
                },
              ),
          ],
          child: _KeyEventProbe(onEvent: (_) {}),
        ),
      );

      expect(find.byKey(tvTestProbeKey), findsOneWidget);
      for (final key in activationKeys) {
        await _withPressedKey(tester, key, () async {
          expect(invocations[key], 1, reason: '$key key-down activation');
          expect(
            await tester.sendKeyRepeatEvent(key),
            isTrue,
            reason: '$key repeat must be consumed by the root host.',
          );
          await pumpTvFrames(tester, frames: 1);
          expect(
            invocations[key],
            1,
            reason: '$key repeat must not activate a second time.',
          );
        });
      }
    });
  }

  testWidgets('remote arrow repeats remain unconsumed and reach focused content', (
    tester,
  ) async {
    configureTvTestView(tester);
    final descendantEvents = <KeyEvent>[];

    await pumpTvKeyboardHarness(
      tester,
      interactionPolicy: AppInteractionPolicy.remote,
      child: AppKeyboardHost(
        interactionPolicy: AppInteractionPolicy.remote,
        bindings: const [],
        child: _KeyEventProbe(onEvent: descendantEvents.add),
      ),
    );

    await _withPressedKey(tester, LogicalKeyboardKey.arrowRight, () async {
      final repeatHandled = await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.arrowRight,
      );
      await pumpTvFrames(tester, frames: 1);

      expect(repeatHandled, isFalse);
      expect(
        descendantEvents.whereType<KeyRepeatEvent>().map(
          (event) => event.logicalKey,
        ),
        contains(LogicalKeyboardKey.arrowRight),
      );
    });
  });

  testWidgets('remote activation repeats cannot re-invoke a real focused control', (
    tester,
  ) async {
    configureTvTestView(tester);
    var invocations = 0;

    await pumpTvPresentationHarness(
      tester,
      capabilities: androidTvCapabilities,
      policyOverride: tvRemotePolicy,
      child: AppKeyboardHost(
        interactionPolicy: AppInteractionPolicy.remote,
        bindings: const [],
        child: Center(
          child: FilledButton(
            autofocus: true,
            onPressed: () => invocations += 1,
            child: const Text('Activate'),
          ),
        ),
      ),
    );

    await _withPressedKey(tester, LogicalKeyboardKey.enter, () async {
      expect(invocations, 1);
      expect(
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter),
        isTrue,
      );
      await pumpTvFrames(tester, frames: 1);
      expect(invocations, 1);
    });
  });

  testWidgets('near-field activation repeats retain ordinary shortcut behavior', (
    tester,
  ) async {
    configureTvTestView(tester);
    var invocations = 0;

    await pumpTvKeyboardHarness(
      tester,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
      child: AppKeyboardHost(
        interactionPolicy: AppInteractionPolicy.precisionPointer,
        bindings: [
          AppKeyboardBinding(
            activator: const SingleActivator(LogicalKeyboardKey.enter),
            onInvoke: () {
              invocations += 1;
              return true;
            },
          ),
        ],
        child: _KeyEventProbe(onEvent: (_) {}),
      ),
    );

    await _withPressedKey(tester, LogicalKeyboardKey.enter, () async {
      expect(invocations, 1);
      expect(
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter),
        isTrue,
      );
      await pumpTvFrames(tester, frames: 1);
      expect(invocations, 2);
    });
  });
}

class _KeyEventProbe extends StatelessWidget {
  const _KeyEventProbe({required this.onEvent});

  final ValueChanged<KeyEvent> onEvent;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        onEvent(event);
        return KeyEventResult.ignored;
      },
      child: Semantics(
        key: tvTestProbeKey,
        label: 'Remote key event probe',
        focusable: true,
        child: const SizedBox.expand(),
      ),
    );
  }
}

Future<void> _withPressedKey(
  WidgetTester tester,
  LogicalKeyboardKey key,
  Future<void> Function() body,
) async {
  await tester.sendKeyDownEvent(key);
  await pumpTvFrames(tester, frames: 1);
  try {
    await body();
  } finally {
    await tester.sendKeyUpEvent(key);
    await pumpTvFrames(tester, frames: 1);
  }
}
