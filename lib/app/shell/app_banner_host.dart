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
///
/// Announcements only show on [showAnnouncements] routes. Blocking gates and
/// entry flows (force update, lock, sign-in) keep the connectivity banner,
/// which still matters there, but never an unrelated announcement.
class AppBannerHost extends ConsumerWidget {
  const AppBannerHost({required this.child, this.showAnnouncements = true, super.key});

  final Widget child;
  final bool showAnnouncements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityVisible = ref.watch(connectivityBannerVisibleProvider);
    final announcementVisible = showAnnouncements && ref.watch(announcementBannerVisibleProvider);
    final hasBanner = connectivityVisible || announcementVisible;
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
        if (showAnnouncements) announcementSlot,
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
