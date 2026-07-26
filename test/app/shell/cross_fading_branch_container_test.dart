// Focused coverage for `crossFadingBranchContainer` (design items 1-2 in
// `docs/nested_navigation_design.md` -> "New coverage is required").
//
// The canonical golden harness renders gallery fixtures through `PreviewFrame`,
// not `AppShell`, so it cannot exercise branch navigation. These tests mount a
// minimal real `StatefulShellRoute` with `navigatorContainerBuilder:
// crossFadingBranchContainer` and three trivial branches, then drive branch
// changes with `router.go(...)` so the container actually builds and animates.
//
// They verify:
//  1. Every `AnimatedOpacity` is correct at the initial, midpoint, and settled
//     frames; inactive branches stay mounted but have pointer/focus/semantics/
//     tickers disabled while only the current branch is interactive.
//  2. `MediaQuery.disableAnimationsOf` collapses the duration to `Duration.zero`
//     for an immediate swap, and a rapid A->B->C retarget never fully reveals a
//     stale branch while still landing on the destination.

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

        // Opacities: branch 0 (current) at 1, branches 1 and 2 at 0.
        final opacities = _currentOpacities(tester);
        expect(opacities, hasLength(3));
        expect(opacities[0], 1.0);
        expect(opacities[1], 0.0);
        expect(opacities[2], 0.0);

        // Each branch's wrappers are present in stable index order so the
        // current branch is the sole interactive/accessible/ticking one.
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

        // Inactive branches stay mounted: their branch page widgets are still
        // in the tree (lazily created once visited), but the wrappers exist
        // regardless because the container always emits one per child.
        expect(_animatedOpacity(tester, 0), isNotNull);
        expect(_animatedOpacity(tester, 1), isNotNull);
        expect(_animatedOpacity(tester, 2), isNotNull);
      },
    );

    testWidgets(
      'mid-fade: outgoing and incoming branches are both strictly partially opaque',
      (tester) async {
        await _pumpShell(tester);

        // Switch to branch 1, then advance ~halfway through AppMotion.standard.
        _go(tester, '/b');
        await tester.pump();
        await tester.pump(AppMotion.standard ~/ 2);

        final opacities = _currentOpacities(tester);
        // Outgoing branch 0 strictly between 0 and 1.
        expect(opacities[0], greaterThan(0));
        expect(opacities[0], lessThan(1));
        // Incoming branch 1 strictly between 0 and 1.
        expect(opacities[1], greaterThan(0));
        expect(opacities[1], lessThan(1));
        // Untouched branch 2 still fully transparent.
        expect(opacities[2], 0.0);

        // Mid-fade the outgoing branch is still painted (not offstaged), so the
        // handoff is a true cross-fade rather than a hide-then-reveal.
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

        // After settling, branch 1 is the sole interactive branch.
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

        // The reduce-motion guard in `_CrossFadingBranchContainer.build`
        // collapses every wrapper's fade duration to `Duration.zero`.
        for (var i = 0; i < 3; i++) {
          expect(
            _animatedOpacity(tester, i).duration,
            Duration.zero,
            reason: 'branch $i duration under disableAnimations',
          );
        }

        // Initial opacities are still correct.
        final initial = _currentOpacities(tester);
        expect(initial[0], 1.0);
        expect(initial[1], 0.0);

        // Switch branch; on the very next frame the destination is already at
        // its target — there is no multi-frame fade.
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

        // Chain the retargets with bounded mid-pumps so neither fade settles.
        // `go('/a')` against an initial location of '/a' is a route no-op; the
        // subsequent `/b` and `/c` switches are what exercise retargeting from
        // a partial opacity (B reversing back to 0, C rising from 0).
        //
        // Each step uses two pumps: the first applies the router rebuild and
        // registers the AnimatedOpacity ticker; the second advances the fake
        // clock so that ticker fires for that branch. A single combined pump
        // would inspect the frame *before* the ticker fired.
        _go(tester, '/a');
        await _advance(tester, const Duration(milliseconds: 30));
        _expectNoStaleBranchFullyOpaque(tester, currentIndex: 0);

        _go(tester, '/b');
        await _advance(tester, const Duration(milliseconds: 30));
        _expectNoStaleBranchFullyOpaque(tester, currentIndex: 1);

        _go(tester, '/c');
        await _advance(tester, const Duration(milliseconds: 30));
        _expectNoStaleBranchFullyOpaque(tester, currentIndex: 2);

        // After settling, destination C is fully opaque and the stale branches
        // have completed their fade back to transparent.
        await tester.pumpAndSettle();
        final settled = _currentOpacities(tester);
        expect(settled[2], 1.0);
        expect(settled[0], 0.0);
        expect(settled[1], 0.0);
      },
    );
  });
}

// --- Shell harness ---------------------------------------------------------

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
  // Tag the subtree so wrapper finders can scope to the container tree and
  // ignore any incidental AnimatedOpacity the Material app adds elsewhere.
  final body = SizedBox(key: _hostKey, child: shell);
  if (!disableAnimations) {
    return body;
  }
  // Wrapping the shell in a MediaQuery with `disableAnimations: true` makes
  // `MediaQuery.disableAnimationsOf(context)` true at the container's context,
  // exercising the reduce-motion branch.
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: body,
  );
}

void _go(WidgetTester tester, String location) {
  final ctx = tester.element(find.byKey(_hostKey));
  GoRouter.of(ctx).go(location);
}

/// Pumps a frame to apply the router rebuild and register the AnimatedOpacity
/// ticker, then advances the fake clock by [duration] so that ticker fires on
/// the next frame's transient-callback phase. The test binding fires transient
/// callbacks (where tickers report elapsed time) BEFORE the build phase that
/// registers them, so a single combined pump would inspect the pre-tick frame.
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

// --- Wrapper finders -------------------------------------------------------
// The container emits a stable index-ordered child list, so the Nth wrapper of
// each type corresponds to branch N. Finders are scoped under `_hostKey` to
// avoid matching incidental AnimatedOpacity/IgnorePointer/etc. from the
// surrounding Material app.

AnimatedOpacity _animatedOpacity(WidgetTester tester, int branchIndex) {
  return tester
      .widgetList<AnimatedOpacity>(_scoped(find.byType(AnimatedOpacity)))
      .elementAt(branchIndex);
}

/// The Nth `AnimatedOpacity` we emit corresponds to branch N. The active
/// branch's `Navigator` also contributes its own `IgnorePointer`s (and other
/// gate widgets) deeper in the subtree, so wrapper lookups must scope to our
/// `AnimatedOpacity` rather than the global widget list.
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

/// Current animated opacity values read from the render objects, not the
/// widget's target. Mid-flight `widget.opacity` is the destination; the
/// underlying `Animation<double>.value` is the live interpolated value.
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
