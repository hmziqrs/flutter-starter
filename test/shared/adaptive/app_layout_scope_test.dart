import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  group('AppLayoutScope', () {
    testWidgets(
      'does not rebuild its subtree on a width change within one layout class',
      (tester) async {
        final builds = <int>[];
        final builder = _countingBuilder(builds);
        _pumpSurface(tester);
        await tester.pumpWidget(_harness(builder));
        await _pumpFrames(tester);

        expect(builds, hasLength(1));
        expect(find.text('compact'), findsOneWidget);

        _resizeSurface(tester, const Size(600, 600));
        await _pumpFrames(tester);

        expect(builds, hasLength(1));
        expect(find.text('compact'), findsOneWidget);
      },
    );

    testWidgets('does not rebuild its subtree on a height-only change', (
      tester,
    ) async {
      final builds = <int>[];
      final builder = _countingBuilder(builds);
      _pumpSurface(tester);
      await tester.pumpWidget(_harness(builder));
      await _pumpFrames(tester);
      expect(builds, hasLength(1));

      _resizeSurface(tester, const Size(500, 400));
      await _pumpFrames(tester);

      expect(builds, hasLength(1));
      expect(find.text('compact'), findsOneWidget);
    });

    testWidgets(
      'rebuilds and republishes the layout class when crossing a breakpoint',
      (tester) async {
        final builds = <int>[];
        final builder = _countingBuilder(builds);
        _pumpSurface(tester);
        await tester.pumpWidget(_harness(builder));
        await _pumpFrames(tester);
        expect(find.text('compact'), findsOneWidget);
        final buildsBeforeCrossing = builds.length;

        _resizeSurface(tester, const Size(1100, 600));
        await _pumpFrames(tester);

        expect(builds.length, greaterThan(buildsBeforeCrossing));
        expect(find.text('expanded'), findsOneWidget);
      },
    );

    testWidgets('rebuilds when a parent supplies a new builder closure', (
      tester,
    ) async {
      final builds = <int>[];
      _pumpSurface(tester);

      await tester.pumpWidget(_harness(_countingBuilder(builds)));
      await _pumpFrames(tester);
      expect(builds, hasLength(1));

      await tester.pumpWidget(_harness(_countingBuilder(builds)));
      await _pumpFrames(tester);

      expect(builds, hasLength(2));
    });
  });
}

AppLayoutBuilder _countingBuilder(List<int> builds) {
  return (context, layoutClass) {
    builds.add(builds.length + 1);
    return const _LayoutClassProbe();
  };
}

class _LayoutClassProbe extends ConsumerWidget {
  const _LayoutClassProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(ref.watch(appLayoutClassProvider).name);
  }
}

void _pumpSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  _resizeSurface(tester, const Size(500, 600));
  addTearDown(tester.view.reset);
}

void _resizeSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
}

Widget _harness(AppLayoutBuilder builder) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: FTheme(
      data: generated.lightTheme,
      child: AppLayoutScope(builder: builder),
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
