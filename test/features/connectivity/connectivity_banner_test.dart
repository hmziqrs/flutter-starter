import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/connectivity/connectivity_banner.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

import '../../infrastructure/connectivity/fake_connectivity_service.dart';

/// Bounded pumps: the offline banner pulses forever, so `pumpAndSettle` hangs.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({
  required FakeConnectivityService service,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      connectivityServiceProvider.overrideWithValue(service),
      appLifecyclePhaseProvider.overrideWith(AppLifecycleController.new),
    ],
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: localeData.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            builder: (context, routerChild) => FTheme(
              data: theme,
              child: FToaster(
                child: FTooltipGroup(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(child: routerChild ?? const SizedBox.shrink()),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ConnectivityBanner(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            home: child,
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders nothing for the online state', (tester) async {
    final service = FakeConnectivityService();
    await tester.pumpWidget(
      _harness(service: service, child: const SizedBox.shrink()),
    );
    await _pumpFrames(tester);

    expect(find.text(t.connectivity.offline), findsNothing);
    expect(find.text(t.connectivity.limited), findsNothing);
  });

  testWidgets('renders the offline banner for the offline state', (tester) async {
    final service = FakeConnectivityService();
    await tester.pumpWidget(
      _harness(service: service, child: const SizedBox.shrink()),
    );
    await _pumpFrames(tester);

    service.emit(ConnectivityState.offline);
    await _pumpFrames(tester);

    expect(find.text(t.connectivity.offline), findsOneWidget);
    expect(find.byIcon(FLucideIcons.wifiOff), findsOneWidget);
  });

  testWidgets('renders the limited banner for the limited state', (tester) async {
    final service = FakeConnectivityService();
    await tester.pumpWidget(
      _harness(service: service, child: const SizedBox.shrink()),
    );
    await _pumpFrames(tester);

    service.emit(ConnectivityState.limited);
    await _pumpFrames(tester);

    expect(find.text(t.connectivity.limited), findsOneWidget);
    expect(find.byIcon(FLucideIcons.wifiLow), findsOneWidget);
  });

  testWidgets('fires the back-online toast on the recovery edge and hides the banner', (
    tester,
  ) async {
    final service = FakeConnectivityService();
    await tester.pumpWidget(
      _harness(service: service, child: const SizedBox.shrink()),
    );
    await _pumpFrames(tester);

    service.emit(ConnectivityState.offline);
    await _pumpFrames(tester);
    expect(find.text(t.connectivity.offline), findsOneWidget);

    service.emit(ConnectivityState.online);
    await _pumpFrames(tester);

    expect(find.text(t.connectivity.offline), findsNothing);
    expect(find.text(t.connectivity.backOnline), findsOneWidget);
  });

  testWidgets('keeps the child visible in every state', (tester) async {
    final service = FakeConnectivityService();
    const childKey = ValueKey('banner-hosted-child');
    await tester.pumpWidget(
      _harness(
        service: service,
        child: const SizedBox(key: childKey),
      ),
    );
    await _pumpFrames(tester);
    expect(find.byKey(childKey), findsOneWidget);

    service.emit(ConnectivityState.offline);
    await _pumpFrames(tester);
    expect(find.byKey(childKey), findsOneWidget);

    service.emit(ConnectivityState.online);
    await _pumpFrames(tester);
    expect(find.byKey(childKey), findsOneWidget);
  });
}
