import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/connectivity/connectivity_banner.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';

String _caseLabel(Translations t, ConnectivityState state) => switch (state) {
  ConnectivityState.online => t.connectivity.online,
  ConnectivityState.offline => t.connectivity.offline,
  ConnectivityState.limited => t.connectivity.limited,
};

List<GalleryCase> buildConnectivityGalleryCases() {
  return [
    for (final state in ConnectivityState.values)
      TypedGalleryCase<ConnectivityState>(
        id: 'connectivity.${state.name}',
        screenId: 'connectivity',
        screenLabelBuilder: (translations) => translations.devGallery.screenConnectivity,
        caseLabelBuilder: (translations) => _caseLabel(translations, state),
        stateFactory: (_) => state,
        pageFactory: (context, state) => _ConnectivityPreview(state: state),
      ),
  ];
}

class _ConnectivityPreview extends StatelessWidget {
  const _ConnectivityPreview({required this.state});

  final ConnectivityState state;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        connectivityServiceProvider.overrideWithValue(_FixedConnectivityService(state)),
      ],
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(context.t.devGallery.preview),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConnectivityBanner(),
          ),
        ],
      ),
    );
  }
}

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
