import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

Widget authTestApp({required Widget home}) {
  return _localizedTestApp(home: home);
}

Widget authTestRouter({
  required String initialRoute,
  required Map<String, WidgetBuilder> routes,
}) {
  return _localizedTestApp(initialRoute: initialRoute, routes: routes);
}

void setAuthTestViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> tapAuthControl(WidgetTester tester, String valueKey) async {
  final control = find.byKey(ValueKey(valueKey));
  tester.binding.focusManager.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(control);
  await tester.pump();
  await tester.tap(control);
  await tester.pump(const Duration(milliseconds: 150));
}

Widget _localizedTestApp({
  Widget? home,
  String? initialRoute,
  Map<String, WidgetBuilder> routes = const {},
}) {
  return ProviderScope(
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: home,
            initialRoute: initialRoute,
            routes: routes,
            locale: localeData.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            builder: (context, child) => FTheme(
              data: theme,
              child: FToaster(
                child: FTooltipGroup(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
