import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_wordmark.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';

void main() {
  Future<void> pump(WidgetTester tester, AppLayoutClass layoutClass, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: generated.lightTheme.toApproximateMaterialTheme(),
          builder: (context, child) => FTheme(data: generated.lightTheme, child: child!),
          home: AuthPageScaffold(
            screenId: 'login',
            layoutClass: layoutClass,
            title: 'Welcome back',
            body: 'Sign in to continue.',
            form: const SizedBox(key: ValueKey('form'), height: 200),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the split layout shows the title once, the wordmark, and the rings', (tester) async {
    await pump(tester, AppLayoutClass.expanded, const Size(1440, 900));

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(AppWordmark), findsOneWidget);
    expect(find.byType(BrandRings), findsOneWidget);
    // The form column holds the kit's small measure and centers on its half.
    final form = tester.getRect(find.byKey(const ValueKey('form')));
    expect(form.width, AuthPageScaffold.columnMaxWidth);
    expect(form.center.dx, closeTo(1440 / 4, 1));
  });

  testWidgets('the compact layout drops the rings and keeps one title', (tester) async {
    await pump(tester, AppLayoutClass.compact, const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(AppWordmark), findsOneWidget);
    expect(find.byType(BrandRings), findsNothing);
  });

  testWidgets('a short window scrolls the column instead of overflowing', (tester) async {
    await pump(tester, AppLayoutClass.expanded, const Size(1200, 320));

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
