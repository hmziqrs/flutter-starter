import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

/// Production default [AnalyticsClient]: records nothing remotely, never
/// throws. Events route through `AppLogger.debug` (a no-op when verbose
/// logging is disabled) so `LogRedactor` scrubs any token/email formats
/// before they reach the log.
final class NoopAnalyticsClient implements AnalyticsClient {
  NoopAnalyticsClient({required this.logger});

  final AppLogger logger;

  @override
  Future<void> track(AnalyticsEvent event) async {
    logger.debug('analytics.track', context: _describeEvent(event));
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    logger.debug(
      'analytics.setUserProperty',
      context: <String, Object?>{'key': property.key},
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    logger.debug(
      'analytics.setUserId',
      context: <String, Object?>{'present': userId != null},
    );
  }

  /// Carries only stable identifiers (route name / target / funnel name +
  /// step), never raw route args.
  static Map<String, Object?> _describeEvent(AnalyticsEvent event) {
    return switch (event) {
      ScreenView(:final routeName) => <String, Object?>{
        'type': 'screen_view',
        'route': routeName,
      },
      Tap(:final target) => <String, Object?>{'type': 'tap', 'target': target},
      FunnelStep(:final name, :final step) => <String, Object?>{
        'type': 'funnel_step',
        'name': name,
        'step': step,
      },
    };
  }
}
