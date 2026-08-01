import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:starter/features/feedback/feedback_sheet.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/settings/accessibility_settings_page.dart';
import 'package:starter/features/settings/analytics_opt_in_controller.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_sidebar_item_group.dart';

enum SettingsSection {
  appearance('appearance'),
  language('language'),
  accessibility('accessibility'),
  account('account'),
  subscription('subscription'),
  privacyAbout('privacy-about');

  const SettingsSection(this.parameter);

  final String parameter;

  static SettingsSection? tryParse(String? value) {
    for (final section in values) {
      if (section.parameter == value) return section;
    }
    return null;
  }
}

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
    return _SettingsScrollFrame(
      title: translations.settings.title,
      child: _SpacedSettingsTiles(
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
              padding: EdgeInsets.all(context.spacing.xl),
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
    return _SettingsScrollFrame(
      title: translations.settings.account,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(translations.settings.accountBody),
          const SizedBox(height: AppSpacing.lg),
          _SpacedSettingsTiles(
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
    return _SettingsScrollFrame(
      title: translations.settings.subscription,
      child: _SettingsCard(
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
    return _SettingsScrollFrame(
      title: translations.settings.privacyAbout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(translations.settings.privacyBody),
          const SizedBox(height: AppSpacing.lg),
          _SpacedSettingsTiles(
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
              const _BiometricUnlockTile(),
              _PasscodeTile(onOpenSetup: widget.onOpenPasscodeSetup),
              const _LockOnBackgroundTile(),
              const _AutoLockDelayTile(),
              const _AnalyticsOptInTile(),
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

mixin _SaveFailureState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _saveFailed = false;

  /// Runs a settings write, surfacing failure as [_saveFailed] for the tile to
  /// render. The failure is also logged: the controller rethrows, so this catch
  /// is where the signal would otherwise be lost entirely.
  Future<void> _run(Future<void> Function() operation) async {
    final logger = ref.read(appLoggerProvider);
    try {
      await operation();
      if (mounted) setState(() => _saveFailed = false);
    } on Object catch (error, stackTrace) {
      logger.warning(
        'settings.save_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'tile': '$T'},
      );
      if (mounted) setState(() => _saveFailed = true);
    }
  }
}

class _HapticsTile extends ConsumerStatefulWidget {
  const _HapticsTile();

  @override
  ConsumerState<_HapticsTile> createState() => _HapticsTileState();
}

class _HapticsTileState extends ConsumerState<_HapticsTile> with _SaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final enabled = ref.watch(settingsControllerProvider).hapticsEnabled;
    final controller = ref.read(settingsControllerProvider.notifier);
    return _ToggleCard(
      keyName: 'haptics',
      label: Text(translations.settings.haptics.title),
      description: Text(translations.settings.haptics.enable),
      value: enabled,
      onChange: (value) => _run(() => controller.setHapticsEnabled(enabled: value)),
      saveFailed: _saveFailed,
    );
  }
}

class _BiometricUnlockTile extends ConsumerStatefulWidget {
  const _BiometricUnlockTile();

  @override
  ConsumerState<_BiometricUnlockTile> createState() => _BiometricUnlockTileState();
}

class _BiometricUnlockTileState extends ConsumerState<_BiometricUnlockTile> with _SaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final enabled = ref.watch(settingsControllerProvider).biometricUnlockEnabled;
    final controller = ref.read(settingsControllerProvider.notifier);
    final availability = ref.watch(biometricAvailabilityProvider);
    final canCheck = availability.maybeWhen(
      data: (report) => report.canCheck,
      orElse: () => false,
    );
    return _ToggleCard(
      keyName: 'biometric',
      label: Text(translations.settings.enableBiometric),
      value: enabled,
      onChange: (value) {
        if (value && !canCheck) return;
        unawaited(_run(() => controller.setBiometricUnlockEnabled(enabled: value)));
      },
      saveFailed: _saveFailed,
    );
  }
}

class _PasscodeTile extends ConsumerStatefulWidget {
  const _PasscodeTile({required this.onOpenSetup});

  final VoidCallback onOpenSetup;

  @override
  ConsumerState<_PasscodeTile> createState() => _PasscodeTileState();
}

class _PasscodeTileState extends ConsumerState<_PasscodeTile> with _SaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final enabled = ref.watch(settingsControllerProvider).passcodeEnabled;
    final controller = ref.read(settingsControllerProvider.notifier);
    return _ToggleCard(
      keyName: 'passcode',
      label: Text(translations.settings.passcode),
      value: enabled,
      onChange: (value) async {
        if (value) {
          await _run(() => controller.setPasscodeEnabled(enabled: true));
          if (context.mounted) widget.onOpenSetup();
        } else {
          await _run(() async {
            await ref.read(passcodeControllerProvider.notifier).disable();
            await controller.setPasscodeEnabled(enabled: false);
          });
        }
      },
      saveFailed: _saveFailed,
    );
  }
}

class _LockOnBackgroundTile extends ConsumerStatefulWidget {
  const _LockOnBackgroundTile();

  @override
  ConsumerState<_LockOnBackgroundTile> createState() => _LockOnBackgroundTileState();
}

class _LockOnBackgroundTileState extends ConsumerState<_LockOnBackgroundTile>
    with _SaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return _ToggleCard(
      keyName: 'lock-on-background',
      label: Text(translations.settings.lockOnBackground),
      value: state.lockOnBackground,
      onChange: (value) {
        if (!state.passcodeEnabled) return;
        unawaited(_run(() => controller.setLockOnBackground(enabled: value)));
      },
      saveFailed: _saveFailed,
    );
  }
}

class _AutoLockDelayTile extends ConsumerStatefulWidget {
  const _AutoLockDelayTile();

  @override
  ConsumerState<_AutoLockDelayTile> createState() => _AutoLockDelayTileState();
}

class _AutoLockDelayTileState extends ConsumerState<_AutoLockDelayTile> with _SaveFailureState {
  static const _options = <int>[0, 30, 60, 300];

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return _ToggleCard(
      keyName: 'auto-lock-delay',
      label: Text(translations.settings.autoLockDelay),
      status: _labelFor(translations, state.autoLockDelaySeconds),
      value: state.autoLockDelaySeconds > 0,
      onChange: (_) {
        if (!state.passcodeEnabled) return;
        final currentIndex = _options.indexOf(state.autoLockDelaySeconds);
        final nextIndex = (currentIndex + 1) % _options.length;
        unawaited(_run(() => controller.setAutoLockDelaySeconds(_options[nextIndex])));
      },
      saveFailed: _saveFailed,
    );
  }

  String _labelFor(Translations translations, int seconds) {
    if (seconds <= 0) return translations.settings.analytics.statusOff;
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    return '${minutes}m';
  }
}

class _AnalyticsOptInTile extends ConsumerStatefulWidget {
  const _AnalyticsOptInTile();

  @override
  ConsumerState<_AnalyticsOptInTile> createState() => _AnalyticsOptInTileState();
}

class _AnalyticsOptInTileState extends ConsumerState<_AnalyticsOptInTile> with _SaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final optedIn = ref.watch(analyticsOptInControllerProvider);
    final controller = ref.read(analyticsOptInControllerProvider.notifier);
    return _ToggleCard(
      keyName: 'analytics',
      label: Text(translations.settings.analytics.optInTitle),
      description: Text(translations.settings.analytics.optInBody),
      status: optedIn
          ? translations.settings.analytics.statusOn
          : translations.settings.analytics.statusOff,
      value: optedIn,
      onChange: (value) => _run(() => controller.setOptIn(value: value)),
      saveFailed: _saveFailed,
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.keyName,
    required this.label,
    required this.value,
    required this.onChange,
    required this.saveFailed,
    this.description,
    this.status,
  });

  final String keyName;
  final Widget label;
  final Widget? description;
  final String? status;
  final bool value;
  final ValueChanged<bool> onChange;
  final bool saveFailed;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FSwitch(
              key: ValueKey('settings-toggle-$keyName'),
              value: value,
              label: label,
              description: description,
              onChange: onChange,
            ),
            if (status case final status?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(status, style: context.theme.typography.body.sm),
            ],
            if (saveFailed) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                translations.common.notConnected,
                key: const ValueKey('settings-toggle-save-error'),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.error,
                ),
              ),
            ],
          ],
        ),
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
    with _SaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return _SettingsScrollFrame(
      title: translations.settings.appearance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsCard(
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
                    onPress: () => _run(() => controller.setThemeMode(mode)),
                    child: Text(_themeModeLabel(translations, mode)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
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
                    onPress: () => _run(() => controller.setAccent(accent)),
                    child: Text(_accentLabel(translations, accent)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
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
                      unawaited(_run(() => controller.setFontScale(_sliderToFontScale(value.max))));
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
          _SettingsCard(
            title: translations.settings.motionPreview,
            child: const _AppearanceMotionPreview(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HapticsTile(),
          if (_saveFailed) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              translations.common.notConnected,
              key: const ValueKey('settings-save-error'),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.error,
              ),
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
    with _SaveFailureState {
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

    return _SettingsScrollFrame(
      title: translations.settings.language,
      child: _SpacedSettingsTiles(
        children: [
          for (final (key, locale, label) in options)
            _LocaleTile(
              key: ValueKey(key),
              selected: settings.localeOverride == locale,
              label: label,
              onPress: () => _run(() => controller.setLocale(locale)),
            ),
          if (_saveFailed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                translations.common.notConnected,
                key: const ValueKey('locale-save-error'),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.error,
                ),
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
    return _SettingsScrollFrame(
      title: context.t.settings.accessibility.title,
      child: const AccessibilityPresetSelector(),
    );
  }
}

class _SettingsScrollFrame extends StatelessWidget {
  const _SettingsScrollFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        context.spacing.xl,
        context.spacing.xl,
        context.spacing.xl,
        context.spacing.xl2,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.presentationTokens.readingContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: context.theme.typography.display.xl2),
                SizedBox(height: context.spacing.xl),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpacedSettingsTiles extends StatelessWidget {
  const _SpacedSettingsTiles({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          children[index],
        ],
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.theme.typography.body.lg),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
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
