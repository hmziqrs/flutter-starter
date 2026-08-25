import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/announcements/announcement_banner.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/connectivity/connectivity_banner.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';

/// Stacks the app-wide banners above routed content.
///
/// The banners take layout space instead of painting over the page, so a
/// degraded-connectivity or announcement banner can never cover a page's top
/// chrome (the paywall's skip action sits exactly there). Banner content owns
/// the top safe-area inset while it is visible, so the routed content below
/// drops its own top padding to avoid insetting twice.
class AppBannerHost extends ConsumerWidget {
  const AppBannerHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBanner =
        ref.watch(connectivityBannerVisibleProvider) ||
        ref.watch(announcementBannerVisibleProvider);

    return Column(
      children: [
        const ConnectivityBanner(),
        const AnnouncementBanner(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: hasBanner,
            child: child,
          ),
        ),
      ],
    );
  }
}
