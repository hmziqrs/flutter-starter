import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The store-side availability of an app update (Google Play in-app update on
/// Android; the App Store listing on iOS).
///
/// This is the *OS-store* path and is non-blocking by design: real store
/// adapters only ever report [UpdateAvailability.noUpdate] or
/// [UpdateAvailability.available] as a dismissible soft nudge. The *server*
/// min-version path (`VersionGateStore`) is the sole source of a hard/soft
/// block and takes precedence — the in-app-update prompt only shows when that
/// path reports `none`.
enum UpdateAvailability {
  /// No update is available, or the store check could not confirm one.
  noUpdate,

  /// The OS store reports a newer build. Surfaced as a dismissible soft nudge
  /// — never as a redirect / hard block.
  available,

  /// A required update. Only the server min-version path produces this; the
  /// OS-store adapters never do.
  required,
}

/// OS-store in-app update port. Production adapters (`AndroidAppUpdateService`
/// via Play in-app update, `IosAppUpdateService` via the App Store deep-link)
/// talk to the OS store directly; the noop default reports
/// [UpdateAvailability.noUpdate] honestly rather than faking an update.
abstract interface class AppUpdateService {
  /// Asks the OS store whether a newer build is available. Never throws —
  /// degrades to [UpdateAvailability.noUpdate]. Real adapters never report
  /// [UpdateAvailability.required] (the server path owns required).
  Future<UpdateAvailability> checkForUpdate();

  /// Starts the OS-store update flow. [immediate] requests the full-screen
  /// flow (Android Play); otherwise the flexible/background flow (Android) or
  /// the store listing (iOS). Never throws.
  Future<void> launchUpdate({bool immediate = false});
}

/// Thrown by [AppUpdateService] implementations only for programmer errors
/// (never for store-check / store-flow failures, which degrade instead).
final class AppUpdateServiceException implements Exception {
  const AppUpdateServiceException({required this.operation});

  final String operation;

  @override
  String toString() => 'AppUpdateServiceException: $operation failed';
}

/// Throws a [StateError] until the composition root overrides it with a
/// concrete adapter (platform-appropriate real adapter, or `NoopAppUpdateService`
/// for web / unsupported / integration-test runs).
final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => throw StateError('AppUpdateService must be overridden at the composition root.'),
);
