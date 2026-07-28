import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The store-side availability of an app update, as reported by the OS store
/// surface (Google Play in-app update on Android; the App Store listing on iOS).
///
/// Exhaustive `switch` over the three variants is required at every call site
/// (the soft-prompt coordinator, the dev-gallery fixtures, and the diagnostics
/// dev triggers) so each branch is handled explicitly. The honest "could not
/// confirm an update" outcome is [UpdateAvailability.noUpdate] — a missing or
/// failed store check must never fabricate [UpdateAvailability.available] or
/// [UpdateAvailability.required] (C2 / C13).
///
/// **Update-gate coordination (see the feature spec + contracts C5):** this is
/// the *OS-store* path and is **non-blocking by design**. Real store adapters
/// only ever report [UpdateAvailability.noUpdate] or [UpdateAvailability.available]
/// and surface a soft, dismissible nudge — they **never** report
/// [UpdateAvailability.required].
/// The *server* min-version path (the `VersionGateStore` /
/// `update-blocker` feature) is the sole source of a hard/soft block and wins
/// precedence: its hard block short-circuits the C5 redirect, and its soft
/// dialog takes the screen. The in-app-update soft prompt is only shown when
/// `VersionGateStore` reports `none`, so the two never BOTH block.
enum UpdateAvailability {
  /// No update is available, or the store check could not confirm one. The
  /// honest default; never fabricated into `available`/`required`.
  noUpdate,

  /// The OS store reports a newer build. Surfaced as a dismissible soft nudge
  /// (a dialog or banner) — never as a redirect / hard block.
  available,

  /// A required update. **Only** the server min-version path
  /// (`VersionGateStore`) produces this; the OS-store adapters never do. Kept
  /// in the enum so the soft-prompt coordinator can distinguish a server-forced
  /// required state from a store-available nudge if a future consumer threads
  /// both signals through one coordinator.
  required,
}

/// OS-store in-app update port.
///
/// Mirrors the [`SettingsStore`](../../features/settings/settings_store.dart)
/// port discipline: a single-purpose, `Future`-returning surface owned under
/// `lib/infrastructure/`, with a typed exception ([AppUpdateServiceException])
/// and `try/on Object` degradation inside adapters. There is **no**
/// `clearAll`-style bulk call. Backend-free per spec — the production adapters
/// (`AndroidAppUpdateService` via Play in-app update, `IosAppUpdateService` via
/// the App Store deep-link) talk to the OS store directly; the deterministic
/// default (`NoopAppUpdateService`) reports [UpdateAvailability.noUpdate]
/// honestly and **never fakes an available update** (C2 / C13).
abstract interface class AppUpdateService {
  /// Asks the OS store whether a newer build is available. Never throws for
  /// store-check failures — degrades to [UpdateAvailability.noUpdate] inside
  /// `try/on Object`. Real store adapters report only [UpdateAvailability.noUpdate]
  /// or [UpdateAvailability.available]; they never report
  /// [UpdateAvailability.required] (the server path owns required).
  Future<UpdateAvailability> checkForUpdate();

  /// Starts the OS-store update flow. When [immediate] is true, requests the
  /// full-screen immediate flow (Android Play); otherwise requests the
  /// flexible/background flow (Android) or opens the store listing (iOS). Never
  /// throws for store-flow failures — degrades inside `try/on Object`. A
  /// no-op on the honest `NoopAppUpdateService` default.
  Future<void> launchUpdate({bool immediate = false});
}

/// Thrown by [AppUpdateService] implementations only for programmer errors
/// (never for store-check / store-flow failures, which degrade honestly to
/// [UpdateAvailability.noUpdate] / a silent no-op).
final class AppUpdateServiceException implements Exception {
  const AppUpdateServiceException({required this.operation});

  final String operation;

  @override
  String toString() => 'AppUpdateServiceException: $operation failed';
}

/// Handwritten Riverpod handle for the [AppUpdateService] port.
///
/// Mirrors `settingsStoreProvider` / `shareServiceProvider`: it throws a
/// [StateError] until the composition root overrides it with a concrete adapter.
/// The composition root selects the platform-appropriate real adapter (Android
/// Play in-app update, iOS App Store deep-link) or the honest
/// `NoopAppUpdateService` for web / unsupported / integration-test runs
/// (selected from `PlatformCapabilities` in `AppDependencies.production`, never
/// via a global), and wires the override in `lib/app/app.dart` as a peer of the
/// other port overrides (HARD RULE 2).
final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => throw StateError('AppUpdateService must be overridden at the composition root.'),
);
