import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/diagnostics/diagnostics_page.dart';
import 'package:starter/app/routing/route_error_page.dart';
import 'package:starter/app/startup/startup_error_view.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/system/system_overlay_fixture.dart';
import 'package:starter/i18n/translations.g.dart';

List<GalleryCase> buildSystemGalleryCases({required AppConfig config}) {
  return <GalleryCase>[
    TypedGalleryCase<String>(
      id: 'system.startupFailure',
      screenId: 'system',
      screenLabelBuilder: (translations) => translations.devGallery.screenSystem,
      caseLabelBuilder: (translations) => translations.devGallery.caseStartupFailure,
      stateFactory: (_) => 'STARTUP-CONFIG',
      pageFactory: (context, diagnosticId) => StartupErrorView(
        diagnosticId: diagnosticId,
        onRetry: () => _showUnavailableFeedback(context),
      ),
    ),
    TypedGalleryCase<_RouteErrorFixtureState>(
      id: 'system.unknownRoute',
      screenId: 'system',
      screenLabelBuilder: (translations) => translations.devGallery.screenSystem,
      caseLabelBuilder: (translations) => translations.devGallery.caseUnknownRoute,
      stateFactory: (_) => const _RouteErrorFixtureState(location: '/gallery/unknown'),
      pageFactory: _buildRouteErrorFixture,
    ),
    TypedGalleryCase<_RouteErrorFixtureState>(
      id: 'system.malformedOtp',
      screenId: 'system',
      screenLabelBuilder: (translations) => translations.devGallery.screenSystem,
      caseLabelBuilder: (translations) => translations.devGallery.caseMalformedOtp,
      stateFactory: (_) => const _RouteErrorFixtureState(
        location: '/auth/otp/not-a-purpose',
        malformedOtp: true,
      ),
      pageFactory: _buildRouteErrorFixture,
    ),
    TypedGalleryCase<AppConfig>(
      id: 'system.diagnostics',
      screenId: 'system',
      screenLabelBuilder: (translations) => translations.devGallery.screenSystem,
      caseLabelBuilder: (translations) => translations.devGallery.caseDiagnostics,
      stateFactory: (_) => config,
      pageFactory: (_, state) => DiagnosticsPage(config: state),
    ),
    ...SystemOverlayFixtureKind.values.map(
      (kind) => TypedGalleryCase<SystemOverlayFixtureState>(
        id: 'overlays.${kind.name}',
        screenId: 'overlays',
        screenLabelBuilder: (translations) => translations.devGallery.screenOverlays,
        caseLabelBuilder: (translations) => _overlayCaseLabel(translations, kind),
        stateFactory: (_) => SystemOverlayFixtureState(kind: kind),
        pageFactory: (_, state) => SystemOverlayFixturePage(state: state),
      ),
    ),
  ];
}

@immutable
final class _RouteErrorFixtureState {
  const _RouteErrorFixtureState({required this.location, this.malformedOtp = false});

  final String location;
  final bool malformedOtp;
}

Widget _buildRouteErrorFixture(BuildContext context, _RouteErrorFixtureState state) {
  return RouteErrorPage(
    location: state.location,
    message: state.malformedOtp ? context.t.routeError.invalidOtpPurpose : null,
    onHome: () => _showUnavailableFeedback(context),
  );
}

String _overlayCaseLabel(Translations translations, SystemOverlayFixtureKind kind) {
  return switch (kind) {
    SystemOverlayFixtureKind.dialog => translations.devGallery.caseDialog,
    SystemOverlayFixtureKind.sheet => translations.devGallery.caseSheet,
    SystemOverlayFixtureKind.toast => translations.devGallery.caseToast,
    SystemOverlayFixtureKind.popover => translations.devGallery.casePopover,
    SystemOverlayFixtureKind.tooltip => translations.devGallery.caseTooltip,
    SystemOverlayFixtureKind.keyboardInset => translations.devGallery.caseKeyboardInset,
  };
}

void _showUnavailableFeedback(BuildContext context) {
  final translations = context.t;
  showFToast(
    context: context,
    title: Text(translations.common.notConnected),
    duration: null,
    suffixBuilder: (context, entry) => FButton(
      key: const ValueKey('system-feedback-close'),
      variant: FButtonVariant.ghost,
      onPress: entry.dismiss,
      child: Text(translations.common.close),
    ),
  );
}
