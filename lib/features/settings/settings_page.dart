import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:starter/features/feedback/feedback_sheet.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/features/settings/accessibility_settings_page.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_section.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/widgets/analytics_opt_in_tile.dart';
import 'package:starter/features/settings/widgets/auto_lock_delay_tile.dart';
import 'package:starter/features/settings/widgets/biometric_unlock_tile.dart';
import 'package:starter/features/settings/widgets/feedback_shake_tile.dart';
import 'package:starter/features/settings/widgets/haptics_tile.dart';
import 'package:starter/features/settings/widgets/inline_save_error_text.dart';
import 'package:starter/features/settings/widgets/lock_on_background_tile.dart';
import 'package:starter/features/settings/widgets/passcode_tile.dart';
import 'package:starter/features/settings/widgets/settings_row.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_section_card.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_sidebar_item_group.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';
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
            // Medium windows render the sections as horizontal tabs — the
            // section column claimed too much width from the content.
            horizontalTabs: layoutClass == AppLayoutClass.medium,
          );

    return SafeArea(bottom: false, child: content);
  }
}

/// The settings page's own frame: the page title at the app scale (24 w500
/// tight, APP-BLOCKS.md) over the section cards, one gap apart.
class _SettingsContentFrame extends StatelessWidget {
  const _SettingsContentFrame({required this.title, required this.sections});

  final String title;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    // APP-BLOCKS.md app type scale: the page title is 24 w500 tight (display
    // .xl), not the 30 of display.xl2.
    final style = context.theme.typography.display.xl;
    return ReadingContentScrollFrame(
      child: SpacedColumn(
        gap: context.spacing.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: style.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.25,
              letterSpacing: -(style.fontSize ?? 24) * 0.02,
            ),
          ),
          SizedBox(height: context.spacing.md),
          ...sections,
        ],
      ),
    );
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
    return _SettingsContentFrame(
      title: translations.settings.title,
      sections: [
        SettingsSectionCard(
          children: [
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-appearance'),
              label: translations.settings.appearance,
              leading: FLucideIcons.palette,
              onPress: onOpenAppearance,
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-language'),
              label: translations.settings.language,
              leading: FLucideIcons.languages,
              onPress: onOpenLanguage,
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-accessibility'),
              label: translations.settings.accessibility.title,
              leading: FLucideIcons.accessibility,
              onPress: onOpenAccessibility,
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-account'),
              label: translations.settings.account,
              leading: FLucideIcons.userRound,
              onPress: onOpenAccount,
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-subscription'),
              label: translations.settings.subscription,
              leading: FLucideIcons.creditCard,
              onPress: onOpenSubscription,
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-privacy-about'),
              label: translations.settings.privacyAbout,
              leading: FLucideIcons.shieldCheck,
              onPress: onOpenPrivacyAbout,
            ),
          ],
        ),
      ],
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
    this.horizontalTabs = false,
  });

  final SettingsSection section;

  /// Renders the six sections as a horizontal segmented tab row above the
  /// content instead of the left-hand section column (medium windows).
  final bool horizontalTabs;
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

  /// Maps a segmented tab's value back to its section-opening callback. The
  /// keys go through a runtime map — enum `.name` getters are illegal in the
  /// const context of switch cases.
  VoidCallback _sectionByName(String name) {
    final byName = <String, VoidCallback>{
      SettingsSection.appearance.name: onOpenAppearance,
      SettingsSection.language.name: onOpenLanguage,
      SettingsSection.accessibility.name: onOpenAccessibility,
      SettingsSection.account.name: onOpenAccount,
      SettingsSection.subscription.name: onOpenSubscription,
      SettingsSection.privacyAbout.name: onOpenPrivacyAbout,
    };
    return byName[name] ?? onOpenAppearance;
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
    final titleStyle = context.theme.typography.display.xl;
    if (horizontalTabs) {
      return _SettingsDirectionalFocusBridge(
        vertical: true,
        navigation: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: FocusScope(
            debugLabel: 'settings-section-navigation',
            child: Padding(
              padding: EdgeInsets.fromLTRB(spacing.xl, spacing.xl, spacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.settings.title,
                    style: titleStyle.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -(titleStyle.fontSize ?? 24) * 0.02,
                    ),
                  ),
                  SizedBox(height: spacing.lg),
                  // Horizontal section tabs keep the whole width for content
                  // on medium windows; the row scrolls when the locale's
                  // labels run long.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AppSegmented<String>(
                      key: const ValueKey('settings-wide-navigation'),
                      value: section.name,
                      onChanged: (name) => _sectionByName(name)(),
                      options: [
                        (
                          value: SettingsSection.appearance.name,
                          label: translations.settings.appearance,
                          key: const ValueKey('settings-wide-appearance'),
                        ),
                        (
                          value: SettingsSection.language.name,
                          label: translations.settings.language,
                          key: const ValueKey('settings-wide-language'),
                        ),
                        (
                          value: SettingsSection.accessibility.name,
                          label: translations.settings.accessibility.title,
                          key: const ValueKey('settings-wide-accessibility'),
                        ),
                        (
                          value: SettingsSection.account.name,
                          label: translations.settings.account,
                          key: const ValueKey('settings-wide-account'),
                        ),
                        (
                          value: SettingsSection.subscription.name,
                          label: translations.settings.subscription,
                          key: const ValueKey('settings-wide-subscription'),
                        ),
                        (
                          value: SettingsSection.privacyAbout.name,
                          label: translations.settings.privacyAbout,
                          key: const ValueKey('settings-wide-privacy-about'),
                        ),
                      ],
                    ),
                  ),
                ],
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
    return _SettingsDirectionalFocusBridge(
      navigation: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: FocusScope(
          debugLabel: 'settings-section-navigation',
          child: SizedBox(
            width: tokens.navigationWidth,
            child: Padding(
              padding: EdgeInsets.all(spacing.xl),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          translations.settings.title,
                          style: titleStyle.copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: -(titleStyle.fontSize ?? 24) * 0.02,
                          ),
                        ),
                        SizedBox(height: spacing.xl),
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
    this.vertical = false,
  });

  final Widget navigation;
  final Widget content;

  /// Stacks the navigation region above the content (horizontal-tab layout)
  /// instead of the side-by-side section-column arrangement; the directional
  /// focus hand-off follows the same axis.
  final bool vertical;

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
      child: widget.vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
            )
          : Row(
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
    final towardContent = widget.vertical
        ? TraversalDirection.down
        : direction == TextDirection.ltr
        ? TraversalDirection.right
        : TraversalDirection.left;
    final towardNavigation = widget.vertical
        ? TraversalDirection.up
        : direction == TextDirection.ltr
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

/// The account section works signed in or anonymous: the profile row always
/// navigates, and the sign-in state row offers sign in when anonymous (never
/// forcing it) or a quiet destructive sign out when authenticated.
class _AccountSettingsContent extends ConsumerWidget {
  const _AccountSettingsContent({
    required this.onOpenProfile,
    required this.onOpenLogin,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final session = ref.watch(sessionControllerProvider);
    return _SettingsContentFrame(
      title: translations.settings.account,
      sections: [
        SettingsSectionCard(
          description: translations.settings.accountBody,
          children: [
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-profile'),
              label: translations.settings.openProfile,
              leading: FLucideIcons.userRoundPen,
              onPress: onOpenProfile,
            ),
            switch (session) {
              AuthAnonymous() => SettingsNavRow(
                rowKey: const ValueKey('settings-open-login'),
                label: translations.auth.login.submit,
                description: translations.session.signedOut,
                leading: FLucideIcons.logIn,
                onPress: onOpenLogin,
              ),
              AuthAuthenticated(:final userId) => SettingsNavRow(
                rowKey: const ValueKey('settings-sign-out'),
                label: translations.settings.signOut,
                description: translations.session.signedInPreview(userId: userId),
                leading: FLucideIcons.logOut,
                destructive: true,
                onPress: () => unawaited(ref.read(sessionControllerProvider.notifier).logout()),
              ),
            },
          ],
        ),
      ],
    );
  }
}

class _SubscriptionSettingsContent extends StatelessWidget {
  const _SubscriptionSettingsContent({required this.onOpenPricing});

  final VoidCallback onOpenPricing;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return _SettingsContentFrame(
      title: translations.settings.subscription,
      sections: [
        SettingsSectionCard(
          description: translations.settings.subscriptionBody,
          children: [
            SettingsNavRow(
              rowKey: const ValueKey('settings-view-pricing'),
              label: translations.settings.openPricing,
              leading: FLucideIcons.creditCard,
              onPress: onOpenPricing,
            ),
          ],
        ),
      ],
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
    return _SettingsContentFrame(
      title: translations.settings.privacyAbout,
      sections: [
        SettingsSectionCard(
          description: translations.settings.privacyBody,
          children: [
            const BiometricUnlockTile(),
            PasscodeTile(onOpenSetup: widget.onOpenPasscodeSetup),
            const LockOnBackgroundTile(),
            const AutoLockDelayTile(),
            const AnalyticsOptInTile(),
          ],
        ),
        SettingsSectionCard(
          title: translations.settings.aboutTitle,
          children: [
            FutureBuilder<String>(
              future: _buildLabel,
              builder: (context, snapshot) => SettingsValueRow(
                label: translations.settings.aboutBuild,
                value:
                    snapshot.data ??
                    (snapshot.hasError
                        ? translations.common.notConnected
                        : translations.common.loading),
              ),
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-terms'),
              label: translations.settings.terms,
              onPress: widget.onOpenTerms,
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-privacy'),
              label: translations.settings.privacy,
              onPress: widget.onOpenPrivacy,
            ),
            SettingsNavRow(
              rowKey: const ValueKey('settings-open-license'),
              label: translations.settings.about.license,
              onPress: widget.onOpenLicense,
            ),
            const FeedbackShakeTile(),
            SettingsNavRow(
              rowKey: const ValueKey('settings-send-feedback'),
              label: translations.feedback.title,
              onPress: () => unawaited(showFeedbackSheet(context: context)),
            ),
          ],
        ),
      ],
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
    final settings = ref.watch(
      settingsControllerProvider.select(
        (state) => (
          themeMode: state.themeMode,
          fontScale: state.fontScale,
          spacingVariant: state.spacingVariant,
          radiusVariant: state.radiusVariant,
        ),
      ),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return _SettingsContentFrame(
      title: translations.settings.appearance,
      sections: [
        SettingsSectionCard(
          children: [
            _SegmentedSettingRow<AppThemeMode>(
              label: translations.settings.themeMode,
              value: settings.themeMode,
              options: [
                for (final mode in AppThemeMode.values)
                  (
                    value: mode,
                    label: _themeModeLabel(translations, mode),
                    key: ValueKey('theme-${mode.name}'),
                  ),
              ],
              onChanged: (mode) => runSave(() => controller.setThemeMode(mode)),
            ),
            _FontScaleSettingRow(
              fontScale: settings.fontScale,
              onChanged: (scale) => runSave(() => controller.setFontScale(scale)),
            ),
            _SegmentedSettingRow<AppSpacingVariant>(
              label: translations.settings.spacing,
              value: settings.spacingVariant,
              options: [
                for (final variant in AppSpacingVariant.values)
                  (
                    value: variant,
                    label: _spacingVariantLabel(translations, variant),
                    key: ValueKey('spacing-${variant.name}'),
                  ),
              ],
              onChanged: (variant) => runSave(() => controller.setSpacingVariant(variant)),
            ),
            _SegmentedSettingRow<AppRadiusVariant>(
              label: translations.settings.cornerRadius,
              value: settings.radiusVariant,
              options: [
                for (final variant in AppRadiusVariant.values)
                  (
                    value: variant,
                    label: _radiusVariantLabel(translations, variant),
                    key: ValueKey('radius-${variant.name}'),
                  ),
              ],
              onChanged: (variant) => runSave(() => controller.setRadiusVariant(variant)),
            ),
            const HapticsTile(),
            if (saveFailed)
              InlineSaveErrorText(
                message: translations.settings.saveFailure,
                valueKey: 'settings-save-error',
              ),
          ],
        ),
        SettingsSectionCard(
          title: translations.settings.motionPreview,
          children: const [_AppearanceMotionPreview()],
        ),
      ],
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
    final localeOverride = ref.watch(
      settingsControllerProvider.select((state) => state.localeOverride),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final options = <(Key, AppLocale?, String)>[
      (
        const ValueKey('locale-system'),
        null,
        translations.settings.languageSystem,
      ),
      (const ValueKey('locale-en'), AppLocale.en, translations.settings.languageEnglish),
      (const ValueKey('locale-ar'), AppLocale.ar, translations.settings.languageArabic),
      (
        const ValueKey('locale-zh-Hans'),
        AppLocale.zhHans,
        translations.settings.languageChinese,
      ),
    ];

    return _SettingsContentFrame(
      title: translations.settings.language,
      sections: [
        SettingsSectionCard(
          title: translations.settings.locale,
          children: [
            for (final (key, locale, label) in options)
              SettingsOptionRow(
                rowKey: key,
                label: label,
                selected: localeOverride == locale,
                onPress: () => runSave(() => controller.setLocale(locale)),
              ),
            if (saveFailed)
              InlineSaveErrorText(
                message: translations.settings.saveFailure,
                valueKey: 'locale-save-error',
              ),
          ],
        ),
      ],
    );
  }
}

class _AccessibilitySettingsContent extends StatelessWidget {
  const _AccessibilitySettingsContent();

  @override
  Widget build(BuildContext context) {
    return _SettingsContentFrame(
      title: context.t.settings.accessibility.title,
      sections: const [AccessibilityPresetSelector()],
    );
  }
}

/// One setting picked from a few options: the brand segmented control
/// (BRAND.md s8) — a thin outline, the picked option on the soft primary
/// fill — under a 14 w500 label.
class _SegmentedSettingRow<T> extends StatelessWidget {
  const _SegmentedSettingRow({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<AppSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.theme.typography.body.sm.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          AppSegmented<T>(options: options, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _FontScaleSettingRow extends StatelessWidget {
  const _FontScaleSettingRow({required this.fontScale, required this.onChanged});

  final double fontScale;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  translations.settings.fontScale,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(fontScale * 100).round()}%',
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FSlider(
            key: const ValueKey('font-scale-slider'),
            control: .liftedContinuous(
              value: FSliderValue(max: _fontScaleToSlider(fontScale)),
              stepPercentage:
                  SettingsState.fontScaleStep /
                  (SettingsState.maximumFontScale - SettingsState.minimumFontScale),
              onChange: (value) => onChanged(_sliderToFontScale(value.max)),
            ),
            semanticValueFormatterCallback: (value) {
              return '${(_sliderToFontScale(value) * 100).round()}%';
            },
            tooltipBuilder: (_, value) => Text('${(_sliderToFontScale(value) * 100).round()}%'),
          ),
        ],
      ),
    );
  }
}

final _motionScale = MovieTweenProperty<double>();
final _motionTurn = MovieTweenProperty<double>();
final _motionTween = MovieTween()
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

class _AppearanceMotionPreview extends StatelessWidget {
  const _AppearanceMotionPreview();

  @override
  Widget build(BuildContext context) {
    // 24px is the largest an icon gets, and it takes the surrounding text
    // color — the primary is never decoration (BRAND.md s4, s6).
    final child = Icon(FLucideIcons.sparkles, size: 24, color: context.theme.colors.foreground);
    if (MediaQuery.disableAnimationsOf(context)) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 20),
        child: Center(child: child),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 20),
      child: PlayAnimationBuilder<Movie>(
        tween: _motionTween,
        duration: _motionTween.duration,
        child: child,
        builder: (context, movie, child) {
          return Center(
            child: Transform.rotate(
              angle: _motionTurn.from(movie),
              child: Transform.scale(scale: _motionScale.from(movie), child: child),
            ),
          );
        },
      ),
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

String _spacingVariantLabel(Translations translations, AppSpacingVariant variant) {
  return switch (variant) {
    AppSpacingVariant.compact => translations.settings.spacingCompact,
    AppSpacingVariant.standard => translations.settings.spacingStandard,
    AppSpacingVariant.relaxed => translations.settings.spacingRelaxed,
  };
}

String _radiusVariantLabel(Translations translations, AppRadiusVariant variant) {
  return switch (variant) {
    AppRadiusVariant.sharp => translations.settings.radiusSharp,
    AppRadiusVariant.rounded => translations.settings.radiusRounded,
    AppRadiusVariant.extraRound => translations.settings.radiusExtraRound,
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
