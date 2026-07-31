import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

final class RecordingAnalyticsClient implements AnalyticsClient {
  final List<AnalyticsEvent> _events = <AnalyticsEvent>[];
  final List<UserProperty> _properties = <UserProperty>[];
  String? _userId;

  List<AnalyticsEvent> get events => List<AnalyticsEvent>.unmodifiable(_events);

  List<UserProperty> get properties => List<UserProperty>.unmodifiable(_properties);

  String? get userId => _userId;

  void clear() {
    _events.clear();
    _properties.clear();
    _userId = null;
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    _events.add(event);
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    _properties.add(property);
  }

  @override
  Future<void> setUserId(String? userId) async {
    _userId = userId;
  }
}
