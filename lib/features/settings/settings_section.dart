/// Deep-link values for the `?section=` query — load-bearing: the settings
/// redirect in route_guards.dart depends on these exact strings.
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
