import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/shell/app_shell.dart';
import 'package:starter/app/shell/television_app_shell.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('AppShell selects television chrome before width presentation', (
    tester,
  ) async {
    _setViewport(tester, const Size(500, 700));
    await _pumpShell(
      tester,
      policy: _tenFootPolicy,
      shell: const AppShell.preview(child: _LayoutClassProbe()),
    );

    expect(find.byKey(const ValueKey('television-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-navigation')), findsNothing);
    expect(find.text('compact'), findsOneWidget);
  });

  testWidgets('near-field AppShell keeps width-derived compact chrome', (
    tester,
  ) async {
    _setViewport(tester, const Size(500, 700));
    await _pumpShell(
      tester,
      policy: _nearFieldPolicy,
      shell: const AppShell.preview(child: SizedBox()),
    );

    expect(find.byKey(const ValueKey('compact-navigation')), findsOneWidget);
    expect(find.byKey(const ValueKey('television-shell')), findsNothing);
  });

  testWidgets('selected destination receives cold autofocus and activates', (
    tester,
  ) async {
    var selected = -1;
    await _pumpTelevisionShell(
      tester,
      selectedIndex: 1,
      onSelectTab: (index) => selected = index,
    );

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.pricing',
    );
    final pricing = tester.widget<FSidebarItem>(
      find.byKey(const ValueKey('television-navigation-pricing')),
    );
    expect(pricing.selected, isTrue);
    expect(pricing.autofocus, isTrue);

    final pricingContext = tester.element(
      find.byKey(const ValueKey('television-navigation-pricing')),
    );
    final style = pricing.style(
      pricingContext.theme.sidebarStyle.groupStyle.itemStyle,
    );
    expect(
      style.focusedOutlineStyle.width,
      pricingContext.presentationTokens.focusOutlineWidth,
    );
    expect(
      style.focusedOutlineStyle.spacing,
      pricingContext.presentationTokens.focusSpacing,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('television-navigation-pricing-target')),
          )
          .height,
      greaterThanOrEqualTo(
        pricingContext.presentationTokens.focusTargetMinSize,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 1);
  });

  for (final textDirection in TextDirection.values) {
    testWidgets(
      '${textDirection.name} mirrors regions and preserves physical directional handoff',
      (tester) async {
        await _pumpTelevisionShell(
          tester,
          selectedIndex: 1,
          textDirection: textDirection,
        );

        final navigationRect = tester.getRect(
          find.byKey(const ValueKey('television-navigation-region')),
        );
        final contentRect = tester.getRect(
          find.byKey(const ValueKey('television-content-region')),
        );
        if (textDirection == TextDirection.ltr) {
          expect(navigationRect.right, lessThanOrEqualTo(contentRect.left));
        } else {
          expect(navigationRect.left, greaterThanOrEqualTo(contentRect.right));
        }

        final towardContent = textDirection == TextDirection.ltr
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft;
        final towardNavigation = textDirection == TextDirection.ltr
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight;

        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'television.navigation.pricing',
        );
        await tester.sendKeyEvent(towardContent);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'television.test.content.first',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'television.test.content.second',
        );

        await tester.sendKeyEvent(towardNavigation);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'television.navigation.pricing',
        );
      },
    );
  }

  testWidgets('vertical navigation remains within the navigation region', (
    tester,
  ) async {
    await _pumpTelevisionShell(tester, selectedIndex: 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.settings',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.pricing',
    );
  });

  testWidgets('branch change retains focus on the selected destination', (
    tester,
  ) async {
    await _pumpTelevisionShell(tester, selectedIndex: 1);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.pricing',
    );

    await _pumpTelevisionShell(tester, selectedIndex: 2);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.settings',
    );
  });

  testWidgets('content handoff bypasses route scopes and restores the last target', (
    tester,
  ) async {
    await _pumpTelevisionShell(
      tester,
      selectedIndex: 1,
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const _ContentFocusTargets(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.test.content.first',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.test.content.second',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.pricing',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.test.content.second',
    );
  });

  testWidgets('content uses local horizontal traversal before returning to navigation', (
    tester,
  ) async {
    await _pumpTelevisionShell(
      tester,
      selectedIndex: 0,
      child: const _HorizontalContentFocusTargets(),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.test.content.left',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.test.content.right',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.test.content.left',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.home',
    );
  });
}

class _LayoutClassProbe extends ConsumerWidget {
  const _LayoutClassProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(ref.watch(appLayoutClassProvider).name);
  }
}

class _ContentFocusTargets extends StatefulWidget {
  const _ContentFocusTargets();

  @override
  State<_ContentFocusTargets> createState() => _ContentFocusTargetsState();
}

class _ContentFocusTargetsState extends State<_ContentFocusTargets> {
  final _first = FocusNode(debugLabel: 'television.test.content.first');
  final _second = FocusNode(debugLabel: 'television.test.content.second');

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            focusNode: _first,
            child: const SizedBox(width: 160, height: 80),
          ),
          Focus(
            focusNode: _second,
            child: const SizedBox(width: 160, height: 80),
          ),
        ],
      ),
    );
  }
}

class _HorizontalContentFocusTargets extends StatefulWidget {
  const _HorizontalContentFocusTargets();

  @override
  State<_HorizontalContentFocusTargets> createState() => _HorizontalContentFocusTargetsState();
}

class _HorizontalContentFocusTargetsState extends State<_HorizontalContentFocusTargets> {
  final _left = FocusNode(debugLabel: 'television.test.content.left');
  final _right = FocusNode(debugLabel: 'television.test.content.right');

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            focusNode: _left,
            child: const SizedBox(width: 160, height: 80),
          ),
          Focus(
            focusNode: _right,
            child: const SizedBox(width: 160, height: 80),
          ),
        ],
      ),
    );
  }
}

Future<void> _pumpTelevisionShell(
  WidgetTester tester, {
  required int selectedIndex,
  ValueChanged<int>? onSelectTab,
  TextDirection textDirection = TextDirection.ltr,
  Widget child = const _ContentFocusTargets(),
}) {
  _setViewport(tester, const Size(1920, 1080));
  return _pumpShell(
    tester,
    policy: _tenFootPolicy,
    textDirection: textDirection,
    shell: TelevisionAppShell(
      selectedIndex: selectedIndex,
      onSelectTab: onSelectTab ?? (_) {},
      child: child,
    ),
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required AppPresentationPolicy policy,
  required Widget shell,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: policy.interactionPolicy,
    presentationPolicy: policy,
  );

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        home: Directionality(
          textDirection: textDirection,
          child: AppPresentationScope(
            policy: policy,
            child: FTheme(
              data: theme,
              accessibility: FAccessibility(
                accessibleNavigation: false,
                motion: FAccessibilityMotion.all,
                focusHighlight: policy.usesDirectionalFocus,
              ),
              child: shell,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

const _tenFootPolicy = AppPresentationPolicy(
  viewingEnvironment: AppViewingEnvironment.tenFoot,
  interactionPolicy: AppInteractionPolicy.remote,
);

const _nearFieldPolicy = AppPresentationPolicy(
  viewingEnvironment: AppViewingEnvironment.nearField,
  interactionPolicy: AppInteractionPolicy.touch,
);
