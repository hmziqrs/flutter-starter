import 'package:flutter/foundation.dart';

/// A single typed search result. Backend-free by default: the search feature
/// matches over a feature-supplied corpus of these (no network, no port), so a
/// result is plain local view-data, not a repository model (audit #2).
@immutable
final class SearchResultViewData {
  const SearchResultViewData({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  /// Stable identifier used as the list `ValueKey` seed.
  final String id;

  /// Primary match label (the field the matcher weights first).
  final String title;

  /// Optional secondary copy.
  final String subtitle;

  /// Case-insensitive, trimmed substring match over [title] and [subtitle]. An
  /// empty/whitespace query matches every item (the "show all" default while
  /// the user has not typed yet). The matcher is intentionally simple — search
  /// is backend-free local filtering; a consumer needing fuzzy/server matching
  /// overrides the corpus provider.
  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return title.toLowerCase().contains(normalized) || subtitle.toLowerCase().contains(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchResultViewData &&
            id == other.id &&
            title == other.title &&
            subtitle == other.subtitle;
  }

  @override
  int get hashCode => Object.hash(id, title, subtitle);

  @override
  String toString() => 'SearchResultViewData(id: $id, title: $title)';
}

/// The page-level view-data: the local corpus the search field filters. The
/// corpus is typed view-data (audit #2); a consumer with a real source overrides
/// `searchCorpusProvider` at the composition root — the default fixture corpus
/// is the spec-mandated backend-free local data ("search matches local data"),
/// not a faked backend (C2 note 2: a real-local deterministic source).
@immutable
final class SearchViewData {
  SearchViewData({required Iterable<SearchResultViewData> results})
    : results = List<SearchResultViewData>.unmodifiable(results);

  /// A backend-free fixture corpus sized to demonstrate pagination (more items
  /// than one page) and matching (overlapping keywords). Real consumers override
  /// `searchCorpusProvider`; this default keeps the app green with zero backend.
  factory SearchViewData.defaults() => SearchViewData(results: _fixtureResults);

  /// The corpus entries.
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
