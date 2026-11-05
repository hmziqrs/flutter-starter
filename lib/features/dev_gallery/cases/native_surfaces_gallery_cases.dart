import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/native_surfaces/surface_snapshot.dart';
import 'package:starter/infrastructure/native_surfaces/method_channel_native_surfaces.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/blocks/page_header.dart';

/// Drives the widgets, menus and live surfaces with sample data, so they can be
/// checked on a device. Dev-only, so the labels are literal English.
List<GalleryCase> buildNativeSurfacesGalleryCases() {
  return [
    TypedGalleryCase<void>(
      id: 'nativeSurfaces.controls',
      screenId: 'nativeSurfaces',
      screenLabelBuilder: (_) => 'Native surfaces',
      caseLabelBuilder: (_) => 'Sample data',
      stateFactory: (_) {},
      pageFactory: (_, _) => const _NativeSurfacesControls(),
    ),
  ];
}

SurfaceSnapshot _sample({required double progress, required SurfaceStatus status}) {
  final percent = (progress * 100).round();
  return SurfaceSnapshot(
    title: 'Starter',
    subtitle: status == SurfaceStatus.success ? 'Build finished' : 'Build running',
    value: '$percent%',
    valueLabel: 'Complete',
    progress: progress,
    status: status,
    updatedAt: DateTime.now(),
    actions: const [
      SurfaceAction(label: 'Home', route: '/'),
      SurfaceAction(label: 'Pricing', route: '/pricing'),
      SurfaceAction(label: 'Settings', route: '/settings'),
    ],
  );
}

class _NativeSurfacesControls extends ConsumerStatefulWidget {
  const _NativeSurfacesControls();

  @override
  ConsumerState<_NativeSurfacesControls> createState() => _NativeSurfacesControlsState();
}

class _NativeSurfacesControlsState extends ConsumerState<_NativeSurfacesControls> {
  String _result = 'Nothing sent yet.';

  void _say(String result) {
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = ref.read(nativeSurfacesProvider);
    final spacing = context.spacing;
    final running = _sample(progress: 0.72, status: SurfaceStatus.active);
    final done = _sample(progress: 1, status: SurfaceStatus.success);
    Widget button(String key, String label, Future<void> Function() onPress) => FButton(
      key: ValueKey('native-surfaces-$key'),
      variant: .outline,
      onPress: () => unawaited(onPress()),
      child: Text(label),
    );
    return SingleChildScrollView(
      padding: context.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.sm,
        children: [
          const AppPageHeader(
            title: 'Native surfaces',
            description: 'Sends sample data to the widgets and menus on this device.',
          ),
          SizedBox(height: spacing.sm),
          button('publish-running', 'Publish a running build', () async {
            await surfaces.publish(running);
            _say('Published 72%.');
          }),
          button('publish-done', 'Publish a finished build', () async {
            await surfaces.publish(done);
            _say('Published 100%.');
          }),
          button('live-start', 'Start live session', () async {
            final started = await surfaces.startLive(running);
            _say(started ? 'Live session started.' : 'This device has no live surface.');
          }),
          button('live-update', 'Update live session', () async {
            await surfaces.updateLive(_sample(progress: 0.9, status: SurfaceStatus.active));
            _say('Live session updated to 90%.');
          }),
          button('live-end', 'End live session', () async {
            await surfaces.endLive();
            _say('Live session ended.');
          }),
          SizedBox(height: spacing.sm),
          Text(_result, key: const ValueKey('native-surfaces-result')),
        ],
      ),
    );
  }
}
