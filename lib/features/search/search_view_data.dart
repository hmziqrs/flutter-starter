import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/i18n/translations.g.dart';

part 'search_view_data.freezed.dart';

@Freezed(toStringOverride: false)
class SearchResultViewData with _$SearchResultViewData {
  const SearchResultViewData({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  @override
  final String id;

  @override
  final String title;
  @override
  final String subtitle;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return title.toLowerCase().contains(normalized) || subtitle.toLowerCase().contains(normalized);
  }

  @override
  String toString() => 'SearchResultViewData(id: $id, title: $title)';
}

@freezed
class SearchViewData with _$SearchViewData {
  SearchViewData({required Iterable<SearchResultViewData> results})
    : results = List<SearchResultViewData>.unmodifiable(results);

  factory SearchViewData.defaults() => SearchViewData(results: _fixtureResults);

  @override
  final List<SearchResultViewData> results;

  /// The bundled corpus, in the current language. A backend replaces it through
  /// `searchCorpusSourceProvider`.
  static List<SearchResultViewData> get _fixtureResults {
    final results = t.search.results;
    return <SearchResultViewData>[
      SearchResultViewData(
        id: 'search-result-auth',
        title: results.auth.title,
        subtitle: results.auth.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-connectivity',
        title: results.connectivity.title,
        subtitle: results.connectivity.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-settings',
        title: results.settings.title,
        subtitle: results.settings.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-biometric',
        title: results.biometric.title,
        subtitle: results.biometric.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-announcements',
        title: results.announcements.title,
        subtitle: results.announcements.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-pricing',
        title: results.pricing.title,
        subtitle: results.pricing.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-onboarding',
        title: results.onboarding.title,
        subtitle: results.onboarding.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-force-update',
        title: results.forceUpdate.title,
        subtitle: results.forceUpdate.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-feature-flags',
        title: results.featureFlags.title,
        subtitle: results.featureFlags.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-notifications',
        title: results.notifications.title,
        subtitle: results.notifications.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-session',
        title: results.session.title,
        subtitle: results.session.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-haptics',
        title: results.haptics.title,
        subtitle: results.haptics.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-accessibility',
        title: results.accessibility.title,
        subtitle: results.accessibility.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-splash',
        title: results.splash.title,
        subtitle: results.splash.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-skeleton',
        title: results.skeleton.title,
        subtitle: results.skeleton.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-form-scaffolding',
        title: results.formScaffolding.title,
        subtitle: results.formScaffolding.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-license',
        title: results.license.title,
        subtitle: results.license.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-deep-links',
        title: results.deepLinks.title,
        subtitle: results.deepLinks.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-permissions',
        title: results.permissions.title,
        subtitle: results.permissions.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-mfa',
        title: results.mfa.title,
        subtitle: results.mfa.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-search',
        title: results.search.title,
        subtitle: results.search.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-profile',
        title: results.profile.title,
        subtitle: results.profile.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-diagnostics',
        title: results.diagnostics.title,
        subtitle: results.diagnostics.subtitle,
      ),
      SearchResultViewData(
        id: 'search-result-state-views',
        title: results.stateViews.title,
        subtitle: results.stateViews.subtitle,
      ),
    ];
  }
}
