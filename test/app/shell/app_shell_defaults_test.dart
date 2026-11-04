import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/i18n/translations.g.dart';

import '../support/pump_app_frames.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      App(
        config: AppConfig(
          environment: AppEnvironment.production,
          enableVerboseLogging: false,
          enableDevTools: false,
          iosAppleId: '',
          allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
        ),
        dependencies: AppDependencies.inMemory(),
        initialLocation: AppRoutes.homePath,
      ),
    );
    await pumpAppFrames(tester);
  }

  testWidgets('a desktop window opens with the labelled sidebar, as the brand shell does', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1440, 900));

    expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('expanded-navigation-account')), findsOneWidget);
  });

  testWidgets('a narrower window opens with the icon rail', (tester) async {
    await pumpAt(tester, const Size(1024, 800));

    expect(find.byKey(const ValueKey('medium-shell')), findsOneWidget);
  });

  testWidgets('the toggle works at tablet widths, not only on desktop', (tester) async {
    await pumpAt(tester, const Size(800, 1000));
    expect(find.byKey(const ValueKey('medium-shell')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('expanded-navigation-toggle')));
    await pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);
  });
}
