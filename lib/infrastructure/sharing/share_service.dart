import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

/// The structured outcome of a share attempt.
///
/// Exhaustive `switch` over the three variants is required at every call site
/// (the dev-gallery fixtures, the diagnostics dev triggers, and the result
/// mapping inside adapters) so each branch is handled explicitly. The honest
/// "no share target" outcome is [ShareResult.unavailable] — a platform with no
/// share sheet (the `NoopShareService` default for web/desktop edge cases) must
/// never fabricate [ShareResult.success] (C2 / C13).
enum ShareResult {
  /// The share sheet opened and the user completed the share (or the OS sheet
  /// dismissed without an explicit cancellation signal — most platforms do not
  /// distinguish "shared" from "dismissed", so a completed presentation is the
  /// honest success outcome).
  success,

  /// The current platform has no native share target. Surfaced by the noop
  /// default and by real adapters when the OS reports sharing is unavailable.
  unavailable,

  /// The user explicitly cancelled the share sheet. Surfaced only when the OS
  /// distinguishes cancellation from completion (iOS `UIActivityViewController`
  /// completion hides this in modern releases; treated as `success` there).
  cancelled,
}

/// Native share-sheet port.
///
/// Mirrors the [`SettingsStore`](../../features/settings/settings_store.dart)
/// port discipline: a single-purpose, `Future`-returning surface owned under
/// `lib/infrastructure/`, with a typed exception ([ShareServiceException]) and
/// `try/on Object` degradation inside adapters. There is **no** `clearAll`-style
/// bulk call. Backend-free per spec — the production adapter
/// (`SharePlusShareService`) talks to the OS share sheet directly via
/// `share_plus`; the deterministic default (`NoopShareService`) reports
/// [ShareResult.unavailable] honestly and **never fakes a successful share**
/// (C2 / C13).
///
/// `List<XFile>` matches `share_plus`'s native `shareXFiles` API, keeping the
/// feature self-contained (no dependency on the unlanded `permissions-media`
/// `PickedMedia` type).
abstract interface class ShareService {
  /// Opens the OS share sheet with [text]. Never throws for sheet failures —
  /// degrades to [ShareResult.unavailable] inside `try/on Object`.
  Future<ShareResult> shareText(String text);

  /// Opens the OS share sheet sharing [files]. Never throws for sheet failures
  /// — degrades to [ShareResult.unavailable] inside `try/on Object`.
  Future<ShareResult> shareFiles(List<XFile> files);
}

/// Thrown by [ShareService] implementations only for programmer errors (never
/// for share-sheet failures, which degrade honestly to [ShareResult.unavailable]).
final class ShareServiceException implements Exception {
  const ShareServiceException({required this.operation});

  final String operation;

  @override
  String toString() => 'ShareServiceException: $operation failed';
}

/// Handwritten Riverpod handle for the [ShareService] port.
///
/// Mirrors `settingsStoreProvider` / `biometricAuthenticatorProvider` /
/// `hapticServiceProvider`: it throws a [StateError] until the composition root
/// overrides it with a concrete adapter. The composition root selects the real
/// `SharePlusShareService` on platforms with a native share target, or the
/// honest `NoopShareService` for web / unsupported / integration-test runs
/// (selected from `PlatformCapabilities` in `AppDependencies.production`, never
/// via a global), and wires the override in `lib/app/app.dart` as a peer of the
/// other port overrides (HARD RULE 2).
final shareServiceProvider = Provider<ShareService>(
  (ref) => throw StateError('ShareService must be overridden at the composition root.'),
);

/// Read-only predicate consulted by the composition root to decide whether the
/// OS exposes a native share target. Pure-Dart derivation from
/// [PlatformCapabilities] (no platform channel, no globals) so the adapter
/// selection stays at the composition root.
///
/// `share_plus` itself degrades gracefully on desktop/web, but the honest
/// `NoopShareService` keeps the hermetic-test default deterministic (a test or
/// golden harness never pops a real OS sheet) and surfaces
/// [ShareResult.unavailable] rather than a fabricated success.
bool shareTargetAvailable(PlatformCapabilities capabilities) {
  if (capabilities.isWeb) return false;
  // Mirror PlatformCapabilities.isApplePlatform: compare against the enum
  // `.name` strings with `==` (an extension method can't be used in a const
  // switch-case label, so the equality form is required here). Desktop
  // (macOS/Windows/Linux) share_plus support is partial and depends on the OS
  // release; treat it as unavailable so the noop default surfaces the honest
  // state and the dev trigger shows the unavailable banner.
  return capabilities.platform == TargetPlatform.android.name ||
      capabilities.platform == TargetPlatform.iOS.name;
}
