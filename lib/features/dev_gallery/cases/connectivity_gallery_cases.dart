import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/connectivity/connectivity_banner.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Immutable, deterministic preview state for the connectivity banner gallery
/// cases. One per [ConnectivityState]; no timers, no plugin, no persistence.
final class ConnectivityGalleryState {
  const ConnectivityGalleryState._(this.state, this.labelBuilder);
  final ConnectivityState state;
  final String Function(Translations translations) labelBuilder;

  static final online = ConnectivityGalleryState._(
    ConnectivityState.online,
    (t) => t.connectivity.online,
  );
  static final offline = ConnectivityGalleryState._(
    ConnectivityState.offline,
    (t) => t.connectivity.offline,
  );
  static final limited = ConnectivityGalleryState._(
    ConnectivityState.limited,
    (t) => t.connectivity.limited,
  );

  static final values = <ConnectivityGalleryState>[online, offline, limited];
}

/// Builds the connectivity banner gallery cases (online / offline / limited).
List<GalleryCase> buildConnectivityGalleryCases() {
  return [
    for (final entry in ConnectivityGalleryState.values)
      TypedGalleryCase<ConnectivityGalleryState>(
        id: 'connectivity.${entry.state.name}',
        screenId: 'connectivity',
        screenLabelBuilder: (translations) => translations.devGallery.screenConnectivity,
        caseLabelBuilder: entry.labelBuilder,
        stateFactory: (_) => entry,
        pageFactory: (context, state) => _ConnectivityPreview(state: state),
      ),
  ];
}

class _ConnectivityPreview extends StatelessWidget {
  const _ConnectivityPreview({required this.state});

  final ConnectivityGalleryState state;

  @override
  Widget build(BuildContext context) {
    // The PreviewFrame already provides a ProviderScope (interactionPolicy);
    // nest one that pins connectivity to the preview state. appLifecyclePhaseProvider
    // resolves to its resumed default, so no lifecycle override is required.
    return ProviderScope(
      overrides: [
        connectivityServiceProvider.overrideWithValue(_FixedConnectivityService(state.state)),
      ],
      child: ConnectivityBanner(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(context.t.devGallery.preview),
        ),
      ),
    );
  }
}

/// Gallery-only [ConnectivityService] pinned to a single state. A deterministic
/// fixture (no plugin, no timers, no persistence) — never fakes an action.
final class _FixedConnectivityService implements ConnectivityService {
  const _FixedConnectivityService(this.state);

  final ConnectivityState state;

  @override
  ConnectivityState get current => state;

  @override
  Stream<ConnectivityState> get states => Stream.value(state);

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {}
}
