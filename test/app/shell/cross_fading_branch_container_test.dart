import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/shell/cross_fading_branch_container.dart';
import 'package:starter/shared/motion/app_motion.dart';

const ValueKey<String> _hostKey = ValueKey<String>('cross-fade-test-host');
const _branchKeys = <String>['branch-a', 'branch-b', 'branch-c'];
const _branchPaths = <String>['/a', '/b', '/c'];

void main() {
  group('item 1 - per-frame opacity and wrapper gating', () {
    testWidgets(
      'initial frame: current branch opaque and interactive; siblings transparent and disabled',
      (tester) async {
        await _pumpShell(tester);

        final opacities = _currentOpacities(tester);
        expect(opacities, hasLength(3));
        expect(opacities[0], 1.0);
        expect(opacities[1], 0.0);
        expect(opacities[2], 0.0);

        expect(_ignorePointer(tester, 0).ignoring, isFalse);
        expect(_excludeFocus(tester, 0).excluding, isFalse);
        expect(_excludeSemantics(tester, 0).excluding, isFalse);
        expect(_tickerMode(tester, 0).enabled, isTrue);
        for (final i in const [1, 2]) {
          expect(_ignorePointer(tester, i).ignoring, isTrue, reason: 'branch $i ignoring');
          expect(_excludeFocus(tester, i).excluding, isTrue, reason: 'branch $i focus excluded');
          expect(
            _excludeSemantics(tester, i).excluding,
            isTrue,
            reason: 'branch $i semantics excluded',
          );
          expect(_tickerMode(tester, i).enabled, isFalse, reason: 'branch $i tickers disabled');
        }

        expect(_animatedOpacity(tester, 0), isNotNull);
        expect(_animatedOpacity(tester, 1), isNotNull);
        expect(_animatedOpacity(tester, 2), isNotNull);
      },
    );

    testWidgets(
      'mid-fade: outgoing and incoming branches are both strictly partially opaque',
      (tester) async {
        await _pumpShell(tester);

        _go(tester, '/b');
        await tester.pump();
        await tester.pump(AppMotion.standard ~/ 2);

        final opacities = _currentOpacities(tester);
        expect(opacities[0], greaterThan(0));
        expect(opacities[0], lessThan(1));
        expect(opacities[1], greaterThan(0));
        expect(opacities[1], lessThan(1));
        expect(opacities[2], 0.0);

        expect(_ignorePointer(tester, 0).ignoring, isTrue);
        expect(_ignorePointer(tester, 1).ignoring, isFalse);
      },
    );

    testWidgets(
      'settled frame: only the new current branch is opaque',
      (tester) async {
        await _pumpShell(tester);
        _go(tester, '/b');
        await tester.pumpAndSettle();

        final opacities = _currentOpacities(tester);
        expect(opacities[0], 0.0);
        expect(opacities[1], 1.0);
        expect(opacities[2], 0.0);

        expect(_ignorePointer(tester, 1).ignoring, isFalse);
        expect(_tickerMode(tester, 1).enabled, isTrue);
        expect(_ignorePointer(tester, 0).ignoring, isTrue);
        expect(_tickerMode(tester, 0).enabled, isFalse);
      },
    );
  });

  group('item 2 - reduce motion and rapid retarget', () {
    testWidgets(
      'disableAnimations: every AnimatedOpacity uses Duration.zero and the swap is immediate',
      (tester) async {
        await _pumpShell(tester, disableAnimations: true);

        for (var i = 0; i < 3; i++) {
          expect(
            _animatedOpacity(tester, i).duration,
            Duration.zero,
            reason: 'branch $i duration under disableAnimations',
          );
        }

        final initial = _currentOpacities(tester);
        expect(initial[0], 1.0);
        expect(initial[1], 0.0);

        _go(tester, '/b');
        await tester.pump();

        final after = _currentOpacities(tester);
        expect(after[1], 1.0, reason: 'incoming branch snaps to opaque');
        expect(after[0], 0.0, reason: 'outgoing branch snaps to transparent');
      },
    );

    testWidgets(
      'rapid retarget A->B->C never fully reveals a stale branch and lands on C',
      (tester) async {
        await _pumpShell(tester);

        _go(tester, '/a');
        await _advance(tester, const Duration(milliseconds: 30));
        _expectNoStaleBranchFullyOpaque(tester, currentIndex: 0);

        _go(tester, '/b');
        await _advance(tester, const Duration(milliseconds: 30));
        _expectNoStaleBranchFullyOpaque(tester, currentIndex: 1);

        _go(tester, '/c');
        await _advance(tester, const Duration(milliseconds: 30));
        _expectNoStaleBranchFullyOpaque(tester, currentIndex: 2);

        await tester.pumpAndSettle();
        final settled = _currentOpacities(tester);
        expect(settled[2], 1.0);
        expect(settled[0], 0.0);
        expect(settled[1], 0.0);
      },
    );
  });

  group('item 3 - runtime focus guarantee', () {
    testWidgets(
      'ExcludeFocus unfocuses the outgoing branch when the current branch changes',
      (tester) async {
        final branchAFocusNode = FocusNode(debugLabel: 'branch-a-focus');
        addTearDown(branchAFocusNode.dispose);

        const hostKey = ValueKey<String>('focus-test-host');
        final router = GoRouter(
          initialLocation: '/a',
          routes: [
            StatefulShellRoute(
              builder: (context, state, shell) => SizedBox(key: hostKey, child: shell),
              navigatorContainerBuilder: crossFadingBranchContainer,
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/a',
                      builder: (context, state) => Focus(
                        focusNode: branchAFocusNode,
                        child: const SizedBox(),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/b',
                      builder: (context, state) => const SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        branchAFocusNode.requestFocus();
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus,
          branchAFocusNode,
          reason: 'branch 0 node should hold primary focus while branch 0 is current',
        );

        GoRouter.of(tester.element(find.byKey(hostKey))).go('/b');
        await tester.pumpAndSettle();

        expect(
          FocusManager.instance.primaryFocus,
          isNot(branchAFocusNode),
          reason:
              'outgoing branch node must lose primary focus once ExcludeFocus '
              're-enables on branch 0',
        );

        GoRouter.of(tester.element(find.byKey(hostKey))).go('/a');
        await tester.pumpAndSettle();
        branchAFocusNode.requestFocus();
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus,
          branchAFocusNode,
          reason: 'branch 0 node must be focusable again after returning to /a',
        );
      },
    );
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  bool disableAnimations = false,
}) async {
  final router = GoRouter(
    initialLocation: '/a',
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) =>
            _host(context, shell, disableAnimations: disableAnimations),
        navigatorContainerBuilder: crossFadingBranchContainer,
        branches: [
          for (var i = 0; i < 3; i++)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: _branchPaths[i],
                  builder: (context, state) => _BranchPage(keyString: _branchKeys[i]),
                ),
              ],
            ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

Widget _host(
  BuildContext context,
  StatefulNavigationShell shell, {
  required bool disableAnimations,
}) {
  final body = SizedBox(key: _hostKey, child: shell);
  if (!disableAnimations) {
    return body;
  }
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: body,
  );
}

void _go(WidgetTester tester, String location) {
  final ctx = tester.element(find.byKey(_hostKey));
  GoRouter.of(ctx).go(location);
}

/// Two-step pump: transient ticker callbacks fire before the build registering the AnimatedOpacity ticker.
Future<void> _advance(WidgetTester tester, Duration duration) async {
  await tester.pump();
  await tester.pump(duration);
}

class _BranchPage extends StatelessWidget {
  const _BranchPage({required this.keyString});

  final String keyString;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(keyString),
      child: Center(child: Text(keyString, textDirection: TextDirection.ltr)),
    );
  }
}

AnimatedOpacity _animatedOpacity(WidgetTester tester, int branchIndex) {
  return tester
      .widgetList<AnimatedOpacity>(_scoped(find.byType(AnimatedOpacity)))
      .elementAt(branchIndex);
}

/// Scope to our AnimatedOpacity: the branch Navigator also emits IgnorePointer/gate widgets deeper down.
Element _branchWrapper(WidgetTester tester, int branchIndex) {
  return tester.elementList(_scoped(find.byType(AnimatedOpacity))).elementAt(branchIndex);
}

T _branchWrapperDescendant<T extends Widget>(WidgetTester tester, int branchIndex) {
  final wrapper = _branchWrapper(tester, branchIndex);
  return tester.widget(
    find
        .descendant(
          of: find.byElementPredicate((element) => identical(element, wrapper)),
          matching: find.byType(T),
        )
        .first,
  );
}

IgnorePointer _ignorePointer(WidgetTester tester, int branchIndex) =>
    _branchWrapperDescendant<IgnorePointer>(tester, branchIndex);

ExcludeFocus _excludeFocus(WidgetTester tester, int branchIndex) =>
    _branchWrapperDescendant<ExcludeFocus>(tester, branchIndex);

ExcludeSemantics _excludeSemantics(WidgetTester tester, int branchIndex) =>
    _branchWrapperDescendant<ExcludeSemantics>(tester, branchIndex);

TickerMode _tickerMode(WidgetTester tester, int branchIndex) =>
    _branchWrapperDescendant<TickerMode>(tester, branchIndex);

/// Reads the render object's live value: mid-flight widget.opacity is the destination, not the current value.
List<double> _currentOpacities(WidgetTester tester) {
  return tester
      .renderObjectList<RenderAnimatedOpacity>(
        _scoped(find.byType(AnimatedOpacity)),
      )
      .map((r) => r.opacity.value)
      .toList();
}

void _expectNoStaleBranchFullyOpaque(
  WidgetTester tester, {
  required int currentIndex,
}) {
  final opacities = _currentOpacities(tester);
  for (var i = 0; i < opacities.length; i++) {
    if (i == currentIndex) {
      continue;
    }
    expect(
      opacities[i],
      lessThan(1.0),
      reason:
          'stale branch $i must never be fully opaque while retargeting '
          '(current=$currentIndex); ${opacities.join(', ')}',
    );
  }
}

Finder _scoped(Finder finder) {
  return find.descendant(of: find.byKey(_hostKey), matching: finder);
}
