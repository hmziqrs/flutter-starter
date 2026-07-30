import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// List-backed [AnalyticsClient] for unit tests. Exercises the real
/// [AnalyticsEvent] sealed hierarchy and exposes captured calls for
/// assertions. Test-only.
final class RecordingAnalyticsClient implements AnalyticsClient {
  final List<AnalyticsEvent> _events = <AnalyticsEvent>[];
  final List<UserProperty> _properties = <UserProperty>[];
  String? _userId;

  /// Unmodifiable view of tracked events, in insertion order.
  List<AnalyticsEvent> get events => List<AnalyticsEvent>.unmodifiable(_events);

  /// Unmodifiable view of set user properties, in insertion order.
  List<UserProperty> get properties => List<UserProperty>.unmodifiable(_properties);

  /// Last identity set via [setUserId], or `null` when dissociated / never set.
  String? get userId => _userId;

  /// Clears all recorded events, properties, and the identity. Test-only
  /// convenience for resetting between assertions within a single test.
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
