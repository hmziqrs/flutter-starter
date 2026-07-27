import 'dart:async';
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/preview_frame.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  testWidgets('constrains every viewport preset to its exact logical size', (tester) async {
    for (final preset in GalleryViewportPresets.values) {
      await _pumpPreview(
        tester,
        GalleryEnvironment.defaults().copyWith(viewport: preset),
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('gallery-preview-viewport'))),
        preset.size,
        reason: preset.id,
      );
      expect(MediaQuery.sizeOf(_probeContext(tester)), preset.size);
      final expectedLayout = switch (preset.id) {
        'below-medium' => AppLayoutClass.compact,
        'at-medium' || 'below-expanded' => AppLayoutClass.medium,
        'at-expanded' => AppLayoutClass.expanded,
        _ => null,
      };
      if (expectedLayout != null) {
        final provider = ProviderScope.containerOf(_probeContext(tester));
        expect(provider.read(appLayoutClassProvider), expectedLayout, reason: preset.id);
      }
    }
  });

  testWidgets('overrides every independent environment dimension', (tester) async {
    final environment = GalleryEnvironment.defaults().copyWith(
      viewport: GalleryViewportPresets.byId('desktop'),
      brightness: Brightness.dark,
      accent: AppAccent.blue,
      locale: AppLocale.ar,
      appFontScale: 1.6,
      systemTextScale: GallerySystemTextScale.maximumNonlinear,
      interactionPolicy: AppInteractionPolicy.hybrid,
      animationsEnabled: false,
      highContrast: true,
      boldText: true,
      safeAreaEnabled: true,
      keyboardInsetsEnabled: true,
      displayFeature: GalleryDisplayFeature.verticalFold,
    );
    await _pumpPreview(tester, environment);

    final context = _probeContext(tester);
    final mediaQuery = MediaQuery.of(context);
    final expectedTheme = ForuiThemeFactory.build(
      brightness: Brightness.dark,
      accent: AppAccent.blue,
      fontScale: 1.6,
      interactionPolicy: AppInteractionPolicy.hybrid,
      responsiveFontScale: AppUnit.fromSize(
        environment.viewport.size,
        devicePixelRatio: 1,
      ).typographyScale,
    );
    final provider = ProviderScope.containerOf(context);
    final fTheme = tester.widget<FTheme>(
      find.byKey(const ValueKey('gallery-preview-forui-theme')),
    );

    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.theme.colors.primary, expectedTheme.colors.primary);
    expect(context.theme.typography.body.md.fontSize, expectedTheme.typography.body.md.fontSize);
    expect(mediaQuery.textScaler, isA<GalleryMaximumTextScaler>());
    expect(provider.read(interactionPolicyOverrideProvider), AppInteractionPolicy.hybrid);
    expect(mediaQuery.disableAnimations, isTrue);
    expect(fTheme.motion.duration, Duration.zero);
    expect(mediaQuery.highContrast, isTrue);
    expect(mediaQuery.boldText, isTrue);
    expect(mediaQuery.padding, PreviewFrame.safeAreaPadding);
    expect(mediaQuery.viewPadding, PreviewFrame.safeAreaPadding);
    expect(mediaQuery.viewInsets, PreviewFrame.keyboardInsets);
    expect(mediaQuery.displayFeatures, hasLength(1));
    expect(mediaQuery.displayFeatures.single.type, DisplayFeatureType.fold);
    expect(mediaQuery.displayFeatures.single.bounds.height, environment.viewport.size.height);
  });

  testWidgets('composes app typography with nonlinear system scaling', (tester) async {
    final environment = GalleryEnvironment.defaults().copyWith(
      appFontScale: 1.6,
      systemTextScale: GallerySystemTextScale.maximumNonlinear,
    );
    await _pumpPreview(tester, environment);

    final context = _probeContext(tester);
    final appScaledFont = context.theme.typography.body.md.fontSize!;
    final composedFont = MediaQuery.textScalerOf(context).scale(appScaledFont);
    final expectedAppFont = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: 1.6,
      interactionPolicy: AppInteractionPolicy.touch,
    ).typography.body.md.fontSize!;

    expect(appScaledFont, expectedAppFont);
    expect(composedFont, const GalleryMaximumTextScaler().scale(expectedAppFont));
    expect(composedFont, isNot(expectedAppFont * 2));
  });

  testWidgets('normal fixtures clear optional insets and retain motion', (tester) async {
    await _pumpPreview(tester, GalleryEnvironment.defaults());

    final context = _probeContext(tester);
    final mediaQuery = MediaQuery.of(context);
    final fTheme = tester.widget<FTheme>(
      find.byKey(const ValueKey('gallery-preview-forui-theme')),
    );

    expect(mediaQuery.textScaler, TextScaler.noScaling);
    expect(mediaQuery.padding, EdgeInsets.zero);
    expect(mediaQuery.viewInsets, EdgeInsets.zero);
    expect(mediaQuery.displayFeatures, isEmpty);
    expect(mediaQuery.disableAnimations, isFalse);
    expect(fTheme.motion.duration, isNot(Duration.zero));
  });

  testWidgets('preserves case state while the environment changes', (tester) async {
    final initial = GalleryEnvironment.defaults();
    await _pumpPreview(tester, initial, child: const _StatefulProbe());

    await tester.tap(find.byKey(const ValueKey('gallery-state-increment')));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await _pumpPreview(
      tester,
      initial.copyWith(brightness: Brightness.dark, appFontScale: 1.6),
      child: const _StatefulProbe(),
    );
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('keeps dialog overlays inside the framed viewport', (tester) async {
    await _pumpPreview(
      tester,
      GalleryEnvironment.defaults(),
      child: const _DialogLauncher(),
    );

    await tester.tap(find.byKey(const ValueKey('gallery-open-local-dialog')));
    await tester.pumpAndSettle();

    final viewport = find.byKey(const ValueKey('gallery-preview-viewport'));
    final dialog = find.byKey(const ValueKey('gallery-local-dialog'));
    expect(find.descendant(of: viewport, matching: dialog), findsOneWidget);
    final viewportRect = tester.getRect(viewport);
    final dialogRect = tester.getRect(dialog);
    expect(viewportRect.contains(dialogRect.topLeft), isTrue);
    expect(dialogRect.right, lessThanOrEqualTo(viewportRect.right));
    expect(dialogRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
  });
}

Future<void> _pumpPreview(
  WidgetTester tester,
  GalleryEnvironment environment, {
  Widget child = const _Probe(),
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  await LocaleSettings.setLocale(environment.locale);
  final hostTheme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          locale: environment.locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: hostTheme.toApproximateMaterialTheme(),
          builder: (context, child) => FTheme(
            data: hostTheme,
            child: child ?? const SizedBox.shrink(),
          ),
          home: PreviewFrame(
            environment: environment,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BuildContext _probeContext(WidgetTester tester) {
  return tester.element(find.byKey(const ValueKey('gallery-environment-probe')));
}

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appLayoutClassProvider);
    return const SizedBox(key: ValueKey('gallery-environment-probe'));
  }
}

class _StatefulProbe extends StatefulWidget {
  const _StatefulProbe();

  @override
  State<_StatefulProbe> createState() => _StatefulProbeState();
}

class _StatefulProbeState extends State<_StatefulProbe> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const ValueKey('gallery-state-increment'),
      onPressed: () => setState(() => count += 1),
      child: Text('$count'),
    );
  }
}

class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        key: const ValueKey('gallery-open-local-dialog'),
        onPressed: () {
          unawaited(
            showFDialog<void>(
              context: context,
              builder: (context, style, animation) => FDialog(
                key: const ValueKey('gallery-local-dialog'),
                animation: animation,
                builder: (_, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(context.t.devGallery.caseDialog, style: style.titleTextStyle),
                ),
              ),
            ),
          );
        },
        child: Text(context.t.devGallery.caseDialog),
      ),
    );
  }
}
