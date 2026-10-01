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
/// chrome (the paywall's skip action sits exactly there). The topmost visible
/// banner owns the top safe-area inset, so the routed content below drops its
/// own top padding to avoid insetting twice.
class AppBannerHost extends ConsumerWidget {
  const AppBannerHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityVisible = ref.watch(connectivityBannerVisibleProvider);
    final hasBanner = connectivityVisible || ref.watch(announcementBannerVisibleProvider);
    final announcementSlot = connectivityVisible
        ? MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: const AnnouncementBanner(),
          )
        : const AnnouncementBanner();

    return Column(
      children: [
        const ConnectivityBanner(),
        announcementSlot,
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
