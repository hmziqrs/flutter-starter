import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/settings_page.dart';

void main() {
  group('SettingsSection', () {
    test('every section round-trips through its query parameter', () {
      for (final section in SettingsSection.values) {
        expect(SettingsSection.tryParse(section.parameter), section);
      }
    });

    test('parameter strings are the deep-link contract', () {
      expect(
        SettingsSection.values.map((section) => section.parameter),
        containsAllInOrder([
          'appearance',
          'language',
          'accessibility',
          'account',
          'subscription',
          'privacy-about',
        ]),
      );
    });

    test('unknown and absent values parse to null', () {
      expect(SettingsSection.tryParse(null), isNull);
      expect(SettingsSection.tryParse(''), isNull);
      expect(SettingsSection.tryParse('privacyAbout'), isNull);
      expect(SettingsSection.tryParse('Appearance'), isNull);
    });
  });
}
