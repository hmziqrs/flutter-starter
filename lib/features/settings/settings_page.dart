import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:starter/features/feedback/feedback_sheet.dart';
import 'package:starter/features/settings/accessibility_settings_page.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_section.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/widgets/analytics_opt_in_tile.dart';
import 'package:starter/features/settings/widgets/auto_lock_delay_tile.dart';
import 'package:starter/features/settings/widgets/biometric_unlock_tile.dart';
import 'package:starter/features/settings/widgets/haptics_tile.dart';
import 'package:starter/features/settings/widgets/inline_save_error_text.dart';
import 'package:starter/features/settings/widgets/labeled_section_card.dart';
import 'package:starter/features/settings/widgets/lock_on_background_tile.dart';
import 'package:starter/features/settings/widgets/passcode_tile.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_sidebar_item_group.dart';
import 'package:starter/shared/widgets/reading_content_scroll_frame.dart';
import 'package:starter/shared/widgets/spaced_column.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({
    required this.section,
    required this.onOpenAppearance,
    required this.onOpenLanguage,
    required this.onOpenAccessibility,
    required this.onOpenAccount,
    required this.onOpenSubscription,
    required this.onOpenPrivacyAbout,
    required this.onOpenProfile,
    required this.onOpenLogin,
    required this.onOpenPricing,
    required this.onOpenPasscodeSetup,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.onOpenLicense,
    required this.loadBuildLabel,
    super.key,
  });

  final SettingsSection? section;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAccessibility;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSubscription;
  final VoidCallback onOpenPrivacyAbout;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLogin;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenPasscodeSetup;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenLicense;
  final Future<String> Function() loadBuildLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final effectiveSection = section ?? SettingsSection.appearance;

    final content = layoutClass == AppLayoutClass.compact
        ? switch (section) {
            SettingsSection.appearance => const _AppearanceSettingsContent(),
            SettingsSection.language => const _LanguageSettingsContent(),
            SettingsSection.accessibility => const _AccessibilitySettingsContent(),
            SettingsSection.account => _AccountSettingsContent(
              onOpenProfile: onOpenProfile,
              onOpenLogin: onOpenLogin,
            ),
            SettingsSection.subscription => _SubscriptionSettingsContent(
              onOpenPricing: onOpenPricing,
            ),
            SettingsSection.privacyAbout => _PrivacyAboutSettingsContent(
              onOpenPasscodeSetup: onOpenPasscodeSetup,
              onOpenTerms: onOpenTerms,
              onOpenPrivacy: onOpenPrivacy,
              onOpenLicense: onOpenLicense,
              loadBuildLabel: loadBuildLabel,
            ),
            null => _SettingsOverview(
              onOpenAppearance: onOpenAppearance,
              onOpenLanguage: onOpenLanguage,
              onOpenAccessibility: onOpenAccessibility,
              onOpenAccount: onOpenAccount,
              onOpenSubscription: onOpenSubscription,
              onOpenPrivacyAbout: onOpenPrivacyAbout,
            ),
          }
        : _SettingsWideLayout(
            section: effectiveSection,
            onOpenAppearance: onOpenAppearance,
            onOpenLanguage: onOpenLanguage,
            onOpenAccessibility: onOpenAccessibility,
            onOpenAccount: onOpenAccount,
            onOpenSubscription: onOpenSubscription,
            onOpenPrivacyAbout: onOpenPrivacyAbout,
            onOpenProfile: onOpenProfile,
            onOpenLogin: onOpenLogin,
            onOpenPricing: onOpenPricing,
            onOpenPasscodeSetup: onOpenPasscodeSetup,
            onOpenTerms: onOpenTerms,
            onOpenPrivacy: onOpenPrivacy,
            onOpenLicense: onOpenLicense,
            loadBuildLabel: loadBuildLabel,
          );

    return SafeArea(bottom: false, child: content);
  }
}

class _SettingsOverview extends StatelessWidget {
  const _SettingsOverview({
    required this.onOpenAppearance,
    required this.onOpenLanguage,
    required this.onOpenAccessibility,
    required this.onOpenAccount,
    required this.onOpenSubscription,
    required this.onOpenPrivacyAbout,
  });

  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAccessibility;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSubscription;
  final VoidCallback onOpenPrivacyAbout;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return ReadingContentScrollFrame(
      title: translations.settings.title,
      child: SpacedColumn(
        children: [
          FTile(
            key: const ValueKey('settings-open-appearance'),
            prefix: const Icon(FLucideIcons.palette),
            title: Text(translations.settings.appearance),
            suffix: const _DirectionalChevron(),
            onPress: onOpenAppearance,
          ),
          FTile(
            key: const ValueKey('settings-open-language'),
            prefix: const Icon(FLucideIcons.languages),
            title: Text(translations.settings.language),
            suffix: const _DirectionalChevron(),
            onPress: onOpenLanguage,
          ),
          FTile(
            key: const ValueKey('settings-open-accessibility'),
            prefix: const Icon(FLucideIcons.accessibility),
            title: Text(translations.settings.accessibility.title),
            suffix: const _DirectionalChevron(),
            onPress: onOpenAccessibility,
          ),
          FTile(
            key: const ValueKey('settings-open-account'),
            prefix: const Icon(FLucideIcons.userRound),
            title: Text(translations.settings.account),
            suffix: const _DirectionalChevron(),
            onPress: onOpenAccount,
          ),
          FTile(
            key: const ValueKey('settings-open-subscription'),
            prefix: const Icon(FLucideIcons.creditCard),
            title: Text(translations.settings.subscription),
            suffix: const _DirectionalChevron(),
            onPress: onOpenSubscription,
          ),
          FTile(
            key: const ValueKey('settings-open-privacy-about'),
            prefix: const Icon(FLucideIcons.shieldCheck),
            title: Text(translations.settings.privacyAbout),
            suffix: const _DirectionalChevron(),
            onPress: onOpenPrivacyAbout,
          ),
        ],
      ),
    );
  }
}

class _SettingsWideLayout extends StatelessWidget {
  const _SettingsWideLayout({
    required this.section,
    required this.onOpenAppearance,
    required this.onOpenLanguage,
    required this.onOpenAccessibility,
    required this.onOpenAccount,
    required this.onOpenSubscription,
    required this.onOpenPrivacyAbout,
    required this.onOpenProfile,
    required this.onOpenLogin,
    required this.onOpenPricing,
    required this.onOpenPasscodeSetup,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.onOpenLicense,
    required this.loadBuildLabel,
  });

  final SettingsSection section;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAccessibility;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSubscription;
  final VoidCallback onOpenPrivacyAbout;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLogin;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenPasscodeSetup;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenLicense;
  final Future<String> Function() loadBuildLabel;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return _SettingsDirectionalFocusBridge(
      navigation: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: FocusScope(
          debugLabel: 'settings-section-navigation',
          child: SizedBox(
            width: context.presentationTokens.navigationWidth,
            child: Padding(
              padding: context.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translations.settings.title,
                    style: context.theme.typography.display.xl,
                  ),
                  SizedBox(height: context.spacing.xl),
                  AppSidebarItemGroup(
                    key: const ValueKey('settings-wide-navigation'),
                    children: [
                      FSidebarItem(
                        key: const ValueKey('settings-wide-appearance'),
                        selected: section == SettingsSection.appearance,
                        icon: const Icon(FLucideIcons.palette),
                        label: Text(translations.settings.appearance),
                        onPress: onOpenAppearance,
                      ),
                      FSidebarItem(
                        key: const ValueKey('settings-wide-language'),
                        selected: section == SettingsSection.language,
                        icon: const Icon(FLucideIcons.languages),
                        label: Text(translations.settings.language),
                        onPress: onOpenLanguage,
                      ),
                      FSidebarItem(
                        key: const ValueKey('settings-wide-accessibility'),
                        selected: section == SettingsSection.accessibility,
                        icon: const Icon(FLucideIcons.accessibility),
                        label: Text(translations.settings.accessibility.title),
                        onPress: onOpenAccessibility,
                      ),
                      FSidebarItem(
                        key: const ValueKey('settings-wide-account'),
                        selected: section == SettingsSection.account,
                        icon: const Icon(FLucideIcons.userRound),
                        label: Text(translations.settings.account),
                        onPress: onOpenAccount,
                      ),
                      FSidebarItem(
                        key: const ValueKey('settings-wide-subscription'),
                        selected: section == SettingsSection.subscription,
                        icon: const Icon(FLucideIcons.creditCard),
                        label: Text(translations.settings.subscription),
                        onPress: onOpenSubscription,
                      ),
                      FSidebarItem(
                        key: const ValueKey('settings-wide-privacy-about'),
                        selected: section == SettingsSection.privacyAbout,
                        icon: const Icon(FLucideIcons.shieldCheck),
                        label: Text(translations.settings.privacyAbout),
                        onPress: onOpenPrivacyAbout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      content: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: FocusScope(
          key: const ValueKey('settings-wide-content'),
          debugLabel: 'settings-section-content',
          child: switch (section) {
            SettingsSection.appearance => const _AppearanceSettingsContent(),
            SettingsSection.language => const _LanguageSettingsContent(),
            SettingsSection.accessibility => const _AccessibilitySettingsContent(),
            SettingsSection.account => _AccountSettingsContent(
              onOpenProfile: onOpenProfile,
              onOpenLogin: onOpenLogin,
            ),
            SettingsSection.subscription => _SubscriptionSettingsContent(
              onOpenPricing: onOpenPricing,
            ),
            SettingsSection.privacyAbout => _PrivacyAboutSettingsContent(
              onOpenPasscodeSetup: onOpenPasscodeSetup,
              onOpenTerms: onOpenTerms,
              onOpenPrivacy: onOpenPrivacy,
              onOpenLicense: onOpenLicense,
              loadBuildLabel: loadBuildLabel,
            ),
          },
        ),
      ),
    );
  }
}

class _SettingsDirectionalFocusBridge extends StatefulWidget {
  const _SettingsDirectionalFocusBridge({
    required this.navigation,
    required this.content,
  });

  final Widget navigation;
  final Widget content;

  @override
  State<_SettingsDirectionalFocusBridge> createState() => _SettingsDirectionalFocusBridgeState();
}

class _SettingsDirectionalFocusBridgeState extends State<_SettingsDirectionalFocusBridge> {
  late final FocusScopeNode _navigationScope = FocusScopeNode(
    debugLabel: 'settings.navigation.region',
  );
  late final FocusScopeNode _contentScope = FocusScopeNode(
    debugLabel: 'settings.content.region',
  );
  late final ReadingOrderTraversalPolicy _contentPolicy = ReadingOrderTraversalPolicy();
  late final WidgetOrderTraversalPolicy _navigationPolicy = WidgetOrderTraversalPolicy();

  @override
  void dispose() {
    _navigationScope.dispose();
    _contentScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
          onInvoke: _handleDirectionalFocus,
        ),
      },
      child: Row(
        children: [
          FocusScope.withExternalFocusNode(
            focusScopeNode: _navigationScope,
            child: widget.navigation,
          ),
          Expanded(
            child: FocusScope.withExternalFocusNode(
              focusScopeNode: _contentScope,
              child: widget.content,
            ),
          ),
        ],
      ),
    );
  }

  Object? _handleDirectionalFocus(DirectionalFocusIntent intent) {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) {
      return null;
    }

    final direction = Directionality.of(context);
    final towardContent = direction == TextDirection.ltr
        ? TraversalDirection.right
        : TraversalDirection.left;
    final towardNavigation = direction == TextDirection.ltr
        ? TraversalDirection.left
        : TraversalDirection.right;

    if (_navigationScope.hasFocus && intent.direction == towardContent) {
      _focusContent();
      return null;
    }
    if (_navigationScope.hasFocus && intent.direction == towardNavigation) {
      Actions.maybeInvoke(context, intent);
      return null;
    }
    if (_navigationScope.hasFocus) {
      _navigationPolicy.inDirection(focused, intent.direction);
      return null;
    }
    if (_contentScope.hasFocus && intent.direction == towardNavigation) {
      _focusNavigation();
      return null;
    }
    if (_contentScope.hasFocus && _contentPolicy.inDirection(focused, intent.direction)) {
      return null;
    }
    return null;
  }

  void _focusContent() {
    final remembered = _rememberedTarget(_contentScope);
    if (remembered != null) {
      remembered.requestFocus();
      return;
    }
    final descendants = _focusableDescendants(_contentScope);
    _contentPolicy.sortDescendants(descendants, _contentScope).firstOrNull?.requestFocus();
  }

  void _focusNavigation() {
    final remembered = _rememberedTarget(_navigationScope);
    if (remembered != null) {
      remembered.requestFocus();
      return;
    }
    final descendants = _focusableDescendants(_navigationScope);
    _navigationPolicy.sortDescendants(descendants, _navigationScope).firstOrNull?.requestFocus();
  }

  Iterable<FocusNode> _focusableDescendants(FocusScopeNode scope) {
    return scope.traversalDescendants.where(
      (node) => node is! FocusScopeNode && node.canRequestFocus && !node.skipTraversal,
    );
  }

  FocusNode? _rememberedTarget(FocusScopeNode scope) {
    var target = scope.focusedChild;
    while (target is FocusScopeNode) {
      target = target.focusedChild;
    }
    if (target == null || !target.canRequestFocus || target.skipTraversal) {
      return null;
    }
    return target;
  }
}

class _AccountSettingsContent extends StatelessWidget {
  const _AccountSettingsContent({
    required this.onOpenProfile,
    required this.onOpenLogin,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return ReadingContentScrollFrame(
      title: translations.settings.account,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(translations.settings.accountBody),
          const SizedBox(height: AppSpacing.lg),
          SpacedColumn(
            children: [
              FTile(
                key: const ValueKey('settings-open-profile'),
                prefix: const Icon(FLucideIcons.userRoundPen),
                title: Text(translations.settings.openProfile),
                suffix: const _DirectionalChevron(),
                onPress: onOpenProfile,
              ),
              FTile(
                key: const ValueKey('settings-open-login'),
                prefix: const Icon(FLucideIcons.logIn),
                title: Text(translations.settings.openLogin),
                suffix: const _DirectionalChevron(),
                onPress: onOpenLogin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSettingsContent extends StatelessWidget {
  const _SubscriptionSettingsContent({required this.onOpenPricing});

  final VoidCallback onOpenPricing;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return ReadingContentScrollFrame(
      title: translations.settings.subscription,
      child: LabeledSectionCard(
        title: translations.settings.openPricing,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(translations.settings.subscriptionBody),
            const SizedBox(height: AppSpacing.lg),
            FButton(
              key: const ValueKey('settings-view-pricing'),
              onPress: onOpenPricing,
              child: Text(translations.settings.openPricing),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyAboutSettingsContent extends StatefulWidget {
  const _PrivacyAboutSettingsContent({
    required this.onOpenPasscodeSetup,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.onOpenLicense,
    required this.loadBuildLabel,
  });

  final VoidCallback onOpenPasscodeSetup;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenLicense;
  final Future<String> Function() loadBuildLabel;

  @override
  State<_PrivacyAboutSettingsContent> createState() => _PrivacyAboutSettingsContentState();
}

class _PrivacyAboutSettingsContentState extends State<_PrivacyAboutSettingsContent> {
  late final Future<String> _buildLabel = widget.loadBuildLabel();

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return ReadingContentScrollFrame(
      title: translations.settings.privacyAbout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(translations.settings.privacyBody),
          const SizedBox(height: AppSpacing.lg),
          SpacedColumn(
            children: [
              FTile(
                title: Text(translations.settings.aboutBuild),
                details: FutureBuilder<String>(
                  future: _buildLabel,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ??
                          (snapshot.hasError
                              ? translations.common.notConnected
                              : translations.common.loading),
                    );
                  },
                ),
              ),
              const BiometricUnlockTile(),
              PasscodeTile(onOpenSetup: widget.onOpenPasscodeSetup),
              const LockOnBackgroundTile(),
              const AutoLockDelayTile(),
              const AnalyticsOptInTile(),
              FTile(
                key: const ValueKey('settings-open-terms'),
                title: Text(translations.settings.terms),
                suffix: const _DirectionalChevron(),
                onPress: widget.onOpenTerms,
              ),
              FTile(
                key: const ValueKey('settings-open-privacy'),
                title: Text(translations.settings.privacy),
                suffix: const _DirectionalChevron(),
                onPress: widget.onOpenPrivacy,
              ),
              FTile(
                key: const ValueKey('settings-open-license'),
                title: Text(translations.settings.about.license),
                suffix: const _DirectionalChevron(),
                onPress: widget.onOpenLicense,
              ),
              FTile(
                key: const ValueKey('settings-send-feedback'),
                title: Text(translations.feedback.title),
                suffix: const _DirectionalChevron(),
                onPress: () => unawaited(showFeedbackSheet(context: context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Directionality.of(context) == TextDirection.rtl
          ? FLucideIcons.chevronLeft
          : FLucideIcons.chevronRight,
    );
  }
}

class _AppearanceSettingsContent extends ConsumerStatefulWidget {
  const _AppearanceSettingsContent();

  @override
  ConsumerState<_AppearanceSettingsContent> createState() => _AppearanceSettingsContentState();
}

class _AppearanceSettingsContentState extends ConsumerState<_AppearanceSettingsContent>
    with SettingsSaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return ReadingContentScrollFrame(
      title: translations.settings.appearance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledSectionCard(
            title: translations.settings.themeMode,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final mode in AppThemeMode.values)
                  FButton(
                    key: ValueKey('theme-${mode.name}'),
                    variant: settings.themeMode == mode ? .primary : .outline,
                    mainAxisSize: .min,
                    onPress: () => runSave(() => controller.setThemeMode(mode)),
                    child: Text(_themeModeLabel(translations, mode)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LabeledSectionCard(
            title: translations.settings.accent,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final accent in AppAccent.values)
                  FButton(
                    key: ValueKey('accent-${accent.name}'),
                    variant: settings.accent == accent ? .primary : .outline,
                    mainAxisSize: .min,
                    onPress: () => runSave(() => controller.setAccent(accent)),
                    child: Text(_accentLabel(translations, accent)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LabeledSectionCard(
            title: translations.settings.fontScale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${(settings.fontScale * 100).round()}%'),
                const SizedBox(height: AppSpacing.md),
                FSlider(
                  key: const ValueKey('font-scale-slider'),
                  control: .liftedContinuous(
                    value: FSliderValue(max: _fontScaleToSlider(settings.fontScale)),
                    stepPercentage:
                        SettingsState.fontScaleStep /
                        (SettingsState.maximumFontScale - SettingsState.minimumFontScale),
                    onChange: (value) {
                      unawaited(
                        runSave(() => controller.setFontScale(_sliderToFontScale(value.max))),
                      );
                    },
                  ),
                  semanticValueFormatterCallback: (value) {
                    return '${(_sliderToFontScale(value) * 100).round()}%';
                  },
                  tooltipBuilder: (_, value) => Text(
                    '${(_sliderToFontScale(value) * 100).round()}%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LabeledSectionCard(
            title: translations.settings.motionPreview,
            child: const _AppearanceMotionPreview(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const HapticsTile(),
          if (saveFailed) ...[
            const SizedBox(height: AppSpacing.md),
            InlineSaveErrorText(
              message: translations.common.notConnected,
              valueKey: 'settings-save-error',
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageSettingsContent extends ConsumerStatefulWidget {
  const _LanguageSettingsContent();

  @override
  ConsumerState<_LanguageSettingsContent> createState() => _LanguageSettingsContentState();
}

class _LanguageSettingsContentState extends ConsumerState<_LanguageSettingsContent>
    with SettingsSaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final options = <(String, AppLocale?, String)>[
      ('locale-system', null, translations.settings.languageSystem),
      ('locale-en', AppLocale.en, translations.settings.languageEnglish),
      ('locale-ar', AppLocale.ar, translations.settings.languageArabic),
      ('locale-zh-Hans', AppLocale.zhHans, translations.settings.languageChinese),
    ];

    return ReadingContentScrollFrame(
      title: translations.settings.language,
      child: SpacedColumn(
        children: [
          for (final (key, locale, label) in options)
            _LocaleTile(
              key: ValueKey(key),
              selected: settings.localeOverride == locale,
              label: label,
              onPress: () => runSave(() => controller.setLocale(locale)),
            ),
          if (saveFailed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: InlineSaveErrorText(
                message: translations.common.notConnected,
                valueKey: 'locale-save-error',
              ),
            ),
        ],
      ),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.selected,
    required this.label,
    required this.onPress,
    super.key,
  });

  final bool selected;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FTile(
      title: Text(label),
      selected: selected,
      suffix: Icon(selected ? FLucideIcons.circleCheck : FLucideIcons.circle),
      onPress: onPress,
    );
  }
}

class _AccessibilitySettingsContent extends StatelessWidget {
  const _AccessibilitySettingsContent();

  @override
  Widget build(BuildContext context) {
    return ReadingContentScrollFrame(
      title: context.t.settings.accessibility.title,
      child: const AccessibilityPresetSelector(),
    );
  }
}

final _motionScale = MovieTweenProperty<double>();
final _motionTurn = MovieTweenProperty<double>();

class _AppearanceMotionPreview extends StatelessWidget {
  const _AppearanceMotionPreview();

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      FLucideIcons.sparkles,
      color: context.theme.colors.primary,
      size: 40,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return Center(child: child);
    }

    final tween = MovieTween()
      ..tween<double>(
        _motionScale,
        Tween(begin: 0.75, end: 1),
        duration: AppMotion.deliberate,
        curve: AppMotion.emphasizedCurve,
      )
      ..tween<double>(
        _motionTurn,
        Tween(begin: -0.04, end: 0),
        duration: AppMotion.deliberate,
        curve: AppMotion.standardCurve,
      );

    return PlayAnimationBuilder<Movie>(
      tween: tween,
      duration: tween.duration,
      child: child,
      builder: (context, movie, child) {
        return Center(
          child: Transform.rotate(
            angle: _motionTurn.from(movie),
            child: Transform.scale(
              scale: _motionScale.from(movie),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

String _themeModeLabel(Translations translations, AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => translations.settings.system,
    AppThemeMode.light => translations.settings.light,
    AppThemeMode.dark => translations.settings.dark,
  };
}

String _accentLabel(Translations translations, AppAccent accent) {
  return switch (accent) {
    AppAccent.neutral => translations.settings.accentNeutral,
    AppAccent.green => translations.settings.accentGreen,
    AppAccent.blue => translations.settings.accentBlue,
    AppAccent.amber => translations.settings.accentAmber,
    AppAccent.rose => translations.settings.accentRose,
    AppAccent.violet => translations.settings.accentViolet,
  };
}

double _fontScaleToSlider(double scale) {
  return (scale - SettingsState.minimumFontScale) /
      (SettingsState.maximumFontScale - SettingsState.minimumFontScale);
}

double _sliderToFontScale(double value) {
  final raw =
      SettingsState.minimumFontScale +
      (value * (SettingsState.maximumFontScale - SettingsState.minimumFontScale));
  final steps = ((raw - SettingsState.minimumFontScale) / SettingsState.fontScaleStep).round();
  return SettingsState.minimumFontScale + (steps * SettingsState.fontScaleStep);
}
