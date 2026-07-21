import 'package:flutter/foundation.dart';

enum HomeStatusKind { ready, adaptive, localized }

@immutable
final class HomeStatusViewData {
  const HomeStatusViewData({required this.id, required this.kind});

  final String id;
  final HomeStatusKind kind;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeStatusViewData && id == other.id && kind == other.kind;
  }

  @override
  int get hashCode => Object.hash(id, kind);
}

@immutable
final class HomeActivityViewData {
  const HomeActivityViewData({required this.id, required this.kind});

  final String id;
  final HomeStatusKind kind;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeActivityViewData && id == other.id && kind == other.kind;
  }

  @override
  int get hashCode => Object.hash(id, kind);
}

@immutable
final class HomeViewData {
  HomeViewData({
    required this.greetingName,
    required Iterable<HomeStatusViewData> statuses,
    required Iterable<HomeActivityViewData> recentActivity,
  }) : statuses = List.unmodifiable(statuses),
       recentActivity = List.unmodifiable(recentActivity);

  factory HomeViewData.defaults({String greetingName = 'Alex'}) {
    return HomeViewData(
      greetingName: greetingName,
      statuses: _defaultStatuses,
      recentActivity: _defaultActivity,
    );
  }

  factory HomeViewData.emptyActivity({String greetingName = 'Alex'}) {
    return HomeViewData(
      greetingName: greetingName,
      statuses: _defaultStatuses,
      recentActivity: const [],
    );
  }

  static const _defaultStatuses = [
    HomeStatusViewData(id: 'ready', kind: HomeStatusKind.ready),
    HomeStatusViewData(id: 'adaptive', kind: HomeStatusKind.adaptive),
    HomeStatusViewData(id: 'localized', kind: HomeStatusKind.localized),
  ];

  static const _defaultActivity = [
    HomeActivityViewData(id: 'foundation-ready', kind: HomeStatusKind.ready),
    HomeActivityViewData(id: 'adaptive-connected', kind: HomeStatusKind.adaptive),
  ];

  final String greetingName;
  final List<HomeStatusViewData> statuses;
  final List<HomeActivityViewData> recentActivity;

  bool get hasRecentActivity => recentActivity.isNotEmpty;
}
