import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/widgets/gallery_preview_body.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

enum AnalyticsOptInPreview { on, off }

List<GalleryCase> buildAnalyticsGalleryCases() {
  return buildEnumGalleryCases<AnalyticsOptInPreview>(
    values: AnalyticsOptInPreview.values,
    idPrefix: 'analytics.optIn',
    screenId: 'analytics',
    screenLabelBuilder: (translations) => translations.devGallery.screenAnalytics,
    caseLabelBuilder: (value) =>
        (translations) => _caseLabel(translations, value),
    pageFactory: (context, state) => _AnalyticsOptInPreview(state: state),
  );
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
    return GalleryPreviewBody(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FSwitch(
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
    );
  }
}
