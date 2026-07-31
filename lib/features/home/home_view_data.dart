import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_view_data.freezed.dart';

enum HomeStatusKind { ready, adaptive, localized }

@freezed
abstract class HomeStatusViewData with _$HomeStatusViewData {
  const factory HomeStatusViewData({required String id, required HomeStatusKind kind}) =
      _HomeStatusViewData;
}

@freezed
abstract class HomeActivityViewData with _$HomeActivityViewData {
  const factory HomeActivityViewData({required String id, required HomeStatusKind kind}) =
      _HomeActivityViewData;
}

@freezed
abstract class HomeViewData with _$HomeViewData {
  const factory HomeViewData({
    required String greetingName,
    required List<HomeStatusViewData> statuses,
    required List<HomeActivityViewData> recentActivity,
  }) = _HomeViewData;

  const HomeViewData._();

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

  bool get hasRecentActivity => recentActivity.isNotEmpty;
}
