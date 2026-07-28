import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Immutable, deterministic preview state for the analytics opt-in gallery
/// cases. One per opt-in value; no timers, no controller, no persistence
/// (C2: the gallery never fakes a backend action — the toggle is disabled so
/// the preview stays stable; no live SecureStore or AnalyticsClient).
enum AnalyticsOptInPreview { on, off }

/// Builds the analytics opt-in gallery cases (opted in / opted out). Each case
/// renders the production SettingsPage opt-in card visually with the toggle
/// disabled, so the copy and on/off status are previewable without a live
/// `SecureStore` or `AnalyticsClient`.
List<GalleryCase> buildAnalyticsGalleryCases() {
  return [
    for (final value in AnalyticsOptInPreview.values)
      TypedGalleryCase<AnalyticsOptInPreview>(
        id: 'analytics.optIn.${value.name}',
        screenId: 'analytics',
        screenLabelBuilder: (translations) => translations.devGallery.screenAnalytics,
        caseLabelBuilder: (translations) => _caseLabel(translations, value),
        stateFactory: (_) => value,
        pageFactory: (context, state) => _AnalyticsOptInPreview(state: state),
      ),
  ];
}

String _caseLabel(Translations translations, AnalyticsOptInPreview value) {
  return switch (value) {
    AnalyticsOptInPreview.on => translations.settings.analytics.statusOn,
    AnalyticsOptInPreview.off => translations.settings.analytics.statusOff,
  };
}

class _AnalyticsOptInPreview extends StatelessWidget {
  const _AnalyticsOptInPreview({required this.state});

  final AnalyticsOptInPreview state;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final optedIn = state == AnalyticsOptInPreview.on;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: FCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FSwitch(
                    // Disabled so the preview never mutates state or writes the
                    // SecureStore key (deterministic fixture).
                    enabled: false,
                    value: optedIn,
                    label: Text(translations.settings.analytics.optInTitle),
                    description: Text(translations.settings.analytics.optInBody),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    optedIn
                        ? translations.settings.analytics.statusOn
                        : translations.settings.analytics.statusOff,
                    style: context.theme.typography.body.sm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
