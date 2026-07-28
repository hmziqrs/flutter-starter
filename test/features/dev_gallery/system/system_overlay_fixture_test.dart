import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/dev_gallery/system/system_gallery_cases.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'system_gallery_test_harness.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('dialog opens with route semantics and closes explicitly', (tester) async {
    await _pumpOverlay(tester, 'overlays.dialog');

    await tester.tap(find.byKey(const ValueKey('overlay-dialog-trigger')));
    await tester.pumpAndSettle();

    final dialog = tester.widget<FDialog>(find.byType(FDialog));
    expect(dialog.semanticsLabel, 'Dialog');
    expect(find.byKey(const ValueKey('overlay-dialog-content')), findsOneWidget);
    expect(find.text('This action is not connected yet.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overlay-dialog-close')));
    await tester.pumpAndSettle();
    expect(find.byType(FDialog), findsNothing);
  });

  testWidgets('sheet opens and closes through its explicit action', (tester) async {
    await _pumpOverlay(tester, 'overlays.sheet');

    await tester.tap(find.byKey(const ValueKey('overlay-sheet-trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overlay-sheet-content')), findsOneWidget);
    expect(find.text('This action is not connected yet.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overlay-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overlay-sheet-content')), findsNothing);
  });

  testWidgets('toast has no auto-dismiss timer and closes explicitly', (tester) async {
    await _pumpOverlay(tester, 'overlays.toast');

    await tester.tap(find.byKey(const ValueKey('overlay-toast-trigger')));
    await tester.pump();
    expect(find.byType(FToast), findsOneWidget);

    await tester.pump(const Duration(minutes: 1));
    expect(find.byType(FToast), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overlay-toast-close')));
    await tester.pumpAndSettle();
    expect(find.byType(FToast), findsNothing);
  });

  testWidgets('popover uses a real controller and exposes semantics', (tester) async {
    await _pumpOverlay(tester, 'overlays.popover');

    final popover = tester.widget<FPopover>(find.byType(FPopover));
    expect(popover.semanticsLabel, 'Popover');

    await tester.tap(find.byKey(const ValueKey('overlay-popover-trigger')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('overlay-popover-content')), findsOneWidget);
    expect(find.text('This action is not connected yet.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overlay-popover-close')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('overlay-popover-content')), findsNothing);
  });

  testWidgets('tooltip is manual, semantic, and has no dwell timers', (tester) async {
    await _pumpOverlay(tester, 'overlays.tooltip');

    final tooltip = tester.widget<FTooltip>(find.byType(FTooltip));
    expect(tooltip.hover, isFalse);
    expect(tooltip.longPress, isFalse);
    expect(tooltip.semanticsLabel, 'This action is not connected yet.');

    await tester.tap(find.byKey(const ValueKey('overlay-tooltip-trigger')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('overlay-tooltip-content')), findsOneWidget);

    await tester.pump(const Duration(minutes: 1));
    expect(find.byKey(const ValueKey('overlay-tooltip-content')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overlay-tooltip-trigger')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('overlay-tooltip-content')), findsNothing);
  });

  testWidgets('keyboard form accounts for the injected bottom inset', (tester) async {
    setSystemGalleryTestViewport(tester, const Size(390, 520));
    await _pumpOverlay(tester, 'overlays.keyboardInset', bottomViewInset: 280);

    expect(find.byKey(const ValueKey('overlay-keyboard-form')), findsOneWidget);
    expect(find.byKey(const ValueKey('overlay-keyboard-field')), findsOneWidget);

    final listView = tester.widget<ListView>(find.byKey(const ValueKey('overlay-keyboard-scroll')));
    final padding = listView.padding!.resolve(TextDirection.ltr);
    expect(padding.bottom, AppSpacing.xl + 280);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('overlay-keyboard-submit')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('overlay-keyboard-feedback')), findsOneWidget);
    expect(find.text('This action is not connected yet.'), findsOneWidget);
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester,
  String id, {
  double bottomViewInset = 0,
}) async {
  final cases = buildSystemGalleryCases(config: _developmentConfig);
  final galleryCase = cases.singleWhere((candidate) => candidate.id == id);
  await tester.pumpWidget(
    systemGalleryTestApp(
      galleryCase: galleryCase,
      bottomViewInset: bottomViewInset,
    ),
  );
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);
