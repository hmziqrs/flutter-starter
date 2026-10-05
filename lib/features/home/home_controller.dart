import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/home/home_view_data.dart';

/// Home's recent-activity feed.
///
/// Backend-free by contract (`plans/feature_roadmap/features/skeleton.md`): the
/// feed composes locally (no network) after the first rendered frame; while it
/// pends, home mirrors `SkeletonView` bones, then transitions to real content.
final homeRecentActivityProvider = FutureProvider<List<HomeActivityViewData>>((
  ref,
) async {
  await SchedulerBinding.instance.endOfFrame;
  return HomeViewData.defaultActivity;
});
