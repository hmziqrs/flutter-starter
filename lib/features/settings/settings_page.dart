import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

enum SettingsSection {
  appearance('appearance'),
  language('language'),
  account('account'),
  subscription('subscription'),
  privacyAbout('privacy-about');

  const SettingsSection(this.parameter);

  final String parameter;

  static SettingsSection? tryParse(String? value) {
    return switch (value) {
      'appearance' => SettingsSection.appearance,
      'language' => SettingsSection.language,
      'account' => SettingsSection.account,
      'subscription' => SettingsSection.subscription,
      'privacy-about' => SettingsSection.privacyAbout,
      _ => null,
    };
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({
    required this.section,
    required this.onOpenAppearance,
    required this.onOpenLanguage,
    required this.onOpenAccount,
    required this.onOpenSubscription,
    required this.onOpenPrivacyAbout,
    required this.onOpenProfile,
    required this.onOpenLogin,
    required this.onOpenPricing,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.loadBuildLabel,
    super.key,
  });

  final SettingsSection? section;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSubscription;
  final VoidCallback onOpenPrivacyAbout;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLogin;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final Future<String> Function() loadBuildLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final effectiveSection = section ?? SettingsSection.appearance;

    if (layoutClass == AppLayoutClass.compact) {
      return switch (section) {
        SettingsSection.appearance => const _AppearanceSettingsContent(),
        SettingsSection.language => const _LanguageSettingsContent(),
        SettingsSection.account => _AccountSettingsContent(
          onOpenProfile: onOpenProfile,
          onOpenLogin: onOpenLogin,
        ),
        SettingsSection.subscription => _SubscriptionSettingsContent(
          onOpenPricing: onOpenPricing,
        ),
        SettingsSection.privacyAbout => _PrivacyAboutSettingsContent(
          onOpenTerms: onOpenTerms,
          onOpenPrivacy: onOpenPrivacy,
          loadBuildLabel: loadBuildLabel,
        ),
        null => _SettingsOverview(
          onOpenAppearance: onOpenAppearance,
          onOpenLanguage: onOpenLanguage,
          onOpenAccount: onOpenAccount,
          onOpenSubscription: onOpenSubscription,
          onOpenPrivacyAbout: onOpenPrivacyAbout,
        ),
      };
    }

    return _SettingsWideLayout(
      section: effectiveSection,
      onOpenAppearance: onOpenAppearance,
      onOpenLanguage: onOpenLanguage,
      onOpenAccount: onOpenAccount,
      onOpenSubscription: onOpenSubscription,
      onOpenPrivacyAbout: onOpenPrivacyAbout,
      onOpenProfile: onOpenProfile,
      onOpenLogin: onOpenLogin,
      onOpenPricing: onOpenPricing,
      onOpenTerms: onOpenTerms,
      onOpenPrivacy: onOpenPrivacy,
      loadBuildLabel: loadBuildLabel,
    );
  }
}

class _SettingsOverview extends StatelessWidget {
  const _SettingsOverview({
    required this.onOpenAppearance,
    required this.onOpenLanguage,
    required this.onOpenAccount,
    required this.onOpenSubscription,
    required this.onOpenPrivacyAbout,
  });

  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSubscription;
  final VoidCallback onOpenPrivacyAbout;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return _SettingsScrollFrame(
      title: translations.settings.title,
      child: FCard(
        child: Column(
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
      ),
    );
  }
}

class _SettingsWideLayout extends StatelessWidget {
  const _SettingsWideLayout({
    required this.section,
    required this.onOpenAppearance,
    required this.onOpenLanguage,
    required this.onOpenAccount,
    required this.onOpenSubscription,
    required this.onOpenPrivacyAbout,
    required this.onOpenProfile,
    required this.onOpenLogin,
    required this.onOpenPricing,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.loadBuildLabel,
  });

  final SettingsSection section;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSubscription;
  final VoidCallback onOpenPrivacyAbout;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLogin;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final Future<String> Function() loadBuildLabel;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Row(
      children: [
        SizedBox(
          width: AppSizes.mediumSidebarWidth,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  translations.settings.title,
                  style: context.theme.typography.display.xl,
                ),
                const SizedBox(height: AppSpacing.xl),
                FSidebarItem(
                  selected: section == SettingsSection.appearance,
                  icon: const Icon(FLucideIcons.palette),
                  label: Text(translations.settings.appearance),
                  onPress: onOpenAppearance,
                ),
                FSidebarItem(
                  selected: section == SettingsSection.language,
                  icon: const Icon(FLucideIcons.languages),
                  label: Text(translations.settings.language),
                  onPress: onOpenLanguage,
                ),
                FSidebarItem(
                  selected: section == SettingsSection.account,
                  icon: const Icon(FLucideIcons.userRound),
                  label: Text(translations.settings.account),
                  onPress: onOpenAccount,
                ),
                FSidebarItem(
                  selected: section == SettingsSection.subscription,
                  icon: const Icon(FLucideIcons.creditCard),
                  label: Text(translations.settings.subscription),
                  onPress: onOpenSubscription,
                ),
                FSidebarItem(
                  selected: section == SettingsSection.privacyAbout,
                  icon: const Icon(FLucideIcons.shieldCheck),
                  label: Text(translations.settings.privacyAbout),
                  onPress: onOpenPrivacyAbout,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (section) {
            SettingsSection.appearance => const _AppearanceSettingsContent(),
            SettingsSection.language => const _LanguageSettingsContent(),
            SettingsSection.account => _AccountSettingsContent(
              onOpenProfile: onOpenProfile,
              onOpenLogin: onOpenLogin,
            ),
            SettingsSection.subscription => _SubscriptionSettingsContent(
              onOpenPricing: onOpenPricing,
            ),
            SettingsSection.privacyAbout => _PrivacyAboutSettingsContent(
              onOpenTerms: onOpenTerms,
              onOpenPrivacy: onOpenPrivacy,
              loadBuildLabel: loadBuildLabel,
            ),
          },
        ),
      ],
    );
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
          FCard(
            child: Column(
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
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.loadBuildLabel,
  });

  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
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
          FCard(
            child: Column(
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
              ],
            ),
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

class _AppearanceSettingsContentState extends ConsumerState<_AppearanceSettingsContent> {
  bool _saveFailed = false;

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

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
      if (mounted) {
        setState(() => _saveFailed = false);
      }
    } on Object {
      if (mounted) {
        setState(() => _saveFailed = true);
      }
    }
  }
}

class _LanguageSettingsContent extends ConsumerStatefulWidget {
  const _LanguageSettingsContent();

  @override
  ConsumerState<_LanguageSettingsContent> createState() => _LanguageSettingsContentState();
}

class _LanguageSettingsContentState extends ConsumerState<_LanguageSettingsContent> {
  bool _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return _SettingsScrollFrame(
      title: translations.settings.language,
      child: FCard(
        child: Column(
          children: [
            _LocaleTile(
              key: const ValueKey('locale-system'),
              selected: settings.localeOverride == null,
              label: translations.settings.languageSystem,
              onPress: () => _setLocale(controller, null),
            ),
            _LocaleTile(
              key: const ValueKey('locale-en'),
              selected: settings.localeOverride == AppLocale.en,
              label: translations.settings.languageEnglish,
              onPress: () => _setLocale(controller, AppLocale.en),
            ),
            _LocaleTile(
              key: const ValueKey('locale-ar'),
              selected: settings.localeOverride == AppLocale.ar,
              label: translations.settings.languageArabic,
              onPress: () => _setLocale(controller, AppLocale.ar),
            ),
            _LocaleTile(
              key: const ValueKey('locale-zh-Hans'),
              selected: settings.localeOverride == AppLocale.zhHans,
              label: translations.settings.languageChinese,
              onPress: () => _setLocale(controller, AppLocale.zhHans),
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
      ),
    );
  }

  Future<void> _setLocale(SettingsController controller, AppLocale? locale) async {
    try {
      await controller.setLocale(locale);
      if (mounted) {
        setState(() => _saveFailed = false);
      }
    } on Object {
      if (mounted) {
        setState(() => _saveFailed = true);
      }
    }
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

class _SettingsScrollFrame extends StatelessWidget {
  const _SettingsScrollFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        context.spacing.xl,
        context.spacing.xl2,
        context.spacing.xl,
        context.spacing.xl3,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readingContentMaxWidth),
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
