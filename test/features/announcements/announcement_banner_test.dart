import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/announcements/announcement_banner.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  group('AnnouncementBannerView', () {
    testWidgets('renders the dismiss control', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: AnnouncementBannerView(
            announcement: AnnouncementFixtures.welcome,
            onDismiss: () {},
            onAction: () {},
          ),
        ),
      );

      expect(find.byIcon(FLucideIcons.x), findsOneWidget);
      expect(find.byType(FAlert), findsOneWidget);
    });

    testWidgets('invokes onDismiss when the in-card X is tapped', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _harness(
          child: AnnouncementBannerView(
            announcement: AnnouncementFixtures.welcome,
            onDismiss: () => dismissed += 1,
            onAction: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(FLucideIcons.x));
      await tester.pumpAndSettle();

      expect(dismissed, 1);
    });

    testWidgets('renders the action control and invokes onAction', (tester) async {
      var acted = 0;
      await tester.pumpWidget(
        _harness(
          child: AnnouncementBannerView(
            announcement: AnnouncementFixtures.changelog,
            onDismiss: () {},
            onAction: () => acted += 1,
          ),
        ),
      );

      expect(find.text('Learn more'), findsOneWidget);

      await tester.tap(find.text('Learn more'));
      await tester.pumpAndSettle();

      expect(acted, 1);
    });

    testWidgets('omits the dismiss control when the announcement is not dismissible', (
      tester,
    ) async {
      final pinned = Announcement(
        id: 'pinned',
        severity: AnnouncementSeverity.critical,
        title: (t) => 'Pinned',
        message: (t) => 'Cannot be dismissed',
        dismissible: false,
      );
      await tester.pumpWidget(
        _harness(
          child: AnnouncementBannerView(
            announcement: pinned,
            onDismiss: () {},
            onAction: () {},
          ),
        ),
      );

      expect(find.byIcon(FLucideIcons.x), findsNothing);
      expect(find.byType(FAlert), findsOneWidget);
      expect(find.text('Pinned'), findsOneWidget);
    });

    testWidgets('renders the welcome copy', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: AnnouncementBannerView(
            announcement: AnnouncementFixtures.welcome,
            onDismiss: () {},
            onAction: () {},
          ),
        ),
      );

      expect(find.text('Welcome to the starter'), findsOneWidget);
    });
  });
}

Widget _harness({required Widget child}) {
  return TranslationProvider(
    child: Builder(
      builder: (context) {
        final theme = generated.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          home: Scaffold(
            body: SafeArea(child: Center(child: child)),
          ),
          builder: (context, built) => FTheme(
            data: theme,
            child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
          ),
        );
      },
    ),
  );
}
