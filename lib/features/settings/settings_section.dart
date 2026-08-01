/// The settings sub-screens addressable by the `?section=` query parameter.
///
/// [parameter] is the deep-link contract consumed by the settings redirect in
/// `lib/app/routing/route_guards.dart`; the strings are load-bearing and must
/// not change without updating that redirect.
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
