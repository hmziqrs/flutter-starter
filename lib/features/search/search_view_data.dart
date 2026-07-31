import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_view_data.freezed.dart';

/// A single typed search result matched over a local, feature-supplied corpus.
@Freezed(toStringOverride: false)
class SearchResultViewData with _$SearchResultViewData {
  const SearchResultViewData({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  /// Stable identifier used as the list `ValueKey` seed.
  @override
  final String id;

  @override
  final String title;
  @override
  final String subtitle;

  /// Case-insensitive, trimmed substring match over [title] and [subtitle]. An
  /// empty/whitespace query matches every item.
  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return title.toLowerCase().contains(normalized) || subtitle.toLowerCase().contains(normalized);
  }

  @override
  String toString() => 'SearchResultViewData(id: $id, title: $title)';
}

/// The page-level view-data: the local corpus the search field filters.
@freezed
class SearchViewData with _$SearchViewData {
  SearchViewData({required Iterable<SearchResultViewData> results})
    : results = List<SearchResultViewData>.unmodifiable(results);

  /// Fixture corpus sized to demonstrate pagination and matching. Real
  /// consumers override `searchCorpusProvider`.
  factory SearchViewData.defaults() => SearchViewData(results: _fixtureResults);

  @override
  final List<SearchResultViewData> results;

  static const _fixtureResults = <SearchResultViewData>[
    SearchResultViewData(
      id: 'search-result-auth',
      title: 'Authentication',
      subtitle: 'Login, register, and password reset flows',
    ),
    SearchResultViewData(
      id: 'search-result-connectivity',
      title: 'Connectivity',
      subtitle: 'Online/offline banner and network state',
    ),
    SearchResultViewData(
      id: 'search-result-settings',
      title: 'Settings',
      subtitle: 'Appearance, language, and accessibility preferences',
    ),
    SearchResultViewData(
      id: 'search-result-biometric',
      title: 'Biometric unlock',
      subtitle: 'Face and fingerprint lock with fallback',
    ),
    SearchResultViewData(
      id: 'search-result-announcements',
      title: 'Announcements',
      subtitle: 'Critical, warning, info, and success banners',
    ),
    SearchResultViewData(
      id: 'search-result-pricing',
      title: 'Pricing',
      subtitle: 'Plans, paywall, and billing periods',
    ),
    SearchResultViewData(
      id: 'search-result-onboarding',
      title: 'Onboarding',
      subtitle: 'First-launch introduction and skip flow',
    ),
    SearchResultViewData(
      id: 'search-result-force-update',
      title: 'Force update',
      subtitle: 'Hard and soft version gates',
    ),
    SearchResultViewData(
      id: 'search-result-feature-flags',
      title: 'Feature flags',
      subtitle: 'Remote configuration toggles',
    ),
    SearchResultViewData(
      id: 'search-result-notifications',
      title: 'Notifications',
      subtitle: 'Push permission and message delivery',
    ),
    SearchResultViewData(
      id: 'search-result-session',
      title: 'Session',
      subtitle: 'Token refresh and sign-out',
    ),
    SearchResultViewData(
      id: 'search-result-haptics',
      title: 'Haptics',
      subtitle: 'Impact, selection, and success feedback',
    ),
    SearchResultViewData(
      id: 'search-result-accessibility',
      title: 'Accessibility presets',
      subtitle: 'Comfortable, large, and dyslexia text presets',
    ),
    SearchResultViewData(
      id: 'search-result-splash',
      title: 'In-app splash',
      subtitle: 'Startup progress and error state',
    ),
    SearchResultViewData(
      id: 'search-result-skeleton',
      title: 'Skeleton loading',
      subtitle: 'Shimmer and reduce-motion placeholders',
    ),
    SearchResultViewData(
      id: 'search-result-form-scaffolding',
      title: 'Form scaffolding',
      subtitle: 'Reusable labeled form field layout',
    ),
    SearchResultViewData(
      id: 'search-result-license',
      title: 'Licenses',
      subtitle: 'OSS license registry and share sheet',
    ),
    SearchResultViewData(
      id: 'search-result-deep-links',
      title: 'Deep links',
      subtitle: 'Inbound universal and app links',
    ),
    SearchResultViewData(
      id: 'search-result-permissions',
      title: 'Permissions',
      subtitle: 'Runtime permission rationale and requests',
    ),
    SearchResultViewData(
      id: 'search-result-mfa',
      title: 'MFA verification',
      subtitle: 'Multi-factor one-time passcode',
    ),
    SearchResultViewData(
      id: 'search-result-search',
      title: 'Search',
      subtitle: 'Debounced in-app search and pagination',
    ),
    SearchResultViewData(
      id: 'search-result-profile',
      title: 'Profile',
      subtitle: 'Editable display name and avatar',
    ),
    SearchResultViewData(
      id: 'search-result-diagnostics',
      title: 'Diagnostics',
      subtitle: 'Environment and build readout',
    ),
    SearchResultViewData(
      id: 'search-result-state-views',
      title: 'State views',
      subtitle: 'Empty, error, and loading placeholders',
    ),
  ];
}
