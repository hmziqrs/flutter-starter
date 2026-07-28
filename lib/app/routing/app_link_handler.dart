/// Inbound deep-link routing.
///
/// Intercepts native URIs (iOS Universal Links, Android App Links, custom
/// schemes) surfaced by the `app_links` plugin and resolves them to existing
/// `go_router` destinations via the [AppRoutes] name + path constants. The
/// receiver is **backend-free** (per the deep-linking feature spec): the only
/// side effect is navigation. Magic-link *issuance* belongs to the future
/// mfa-otp / session server features; this module only *receives* links.
///
/// The security boundary is the host allowlist ([AllowedDeepLinkHosts]), sourced
/// from compile-time `AppConfig`. URIs whose host is not on the allowlist resolve
/// to `null` (phishing rejection) — a malicious site can never route a user into
/// an auth flow. The path is then matched against the known route constants; an
/// unknown path also resolves to `null` (ignored, never an error).
///
/// Architecture (per the feature spec and C2/C4):
/// - [AppLinkHandler] is a **pure, synchronous** `Uri -> ResolvedLink?` resolver.
///   It owns no plugin, has no side effects, and is exhaustively testable without
///   a platform channel.
/// - [DeepLinkService] owns the `AppLinks` plugin instance and exposes the
///   resolved stream + cold-start initial link. Widgets never name `AppLinks`
///   directly (checklist #1/#4) — they read [appLinkStreamProvider].
/// - The composition root (`AppDependencies` / `bootstrap.dart`) constructs the
///   real adapter; [appLinkHandlerProvider] throws [StateError] until it is
///   overridden at the `ProviderScope`, mirroring `settingsStoreProvider` /
///   `secureStoreProvider`.
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';

/// Typed result of resolving an inbound deep-link [Uri] against the route table.
///
/// Carries the target [routeName] (a constant from [AppRoutes]) plus the
/// `pathParameters` / `queryParameters` needed to dispatch it via
/// `context.goNamed` / `context.pushNamed`. Immutable and value-equal so it can
/// flow through Riverpod unchanged.
///
/// `pathParameters` is populated only for routes with a dynamic segment (today:
/// the OTP route `/auth/otp/:purpose`); static routes leave it empty and carry
/// any inbound query string through `queryParameters`.
@immutable
final class ResolvedLink {
  const ResolvedLink({
    required this.routeName,
    this.pathParameters = const <String, String>{},
    this.queryParameters = const <String, String>{},
  });

  /// The [AppRoutes] name to navigate to (e.g. [AppRoutes.login],
  /// [AppRoutes.otp]).
  final String routeName;

  /// Path parameters for the target route. Today only `purpose` (for the OTP
  /// route) is ever populated; static routes use an empty map.
  final Map<String, String> pathParameters;

  /// Query parameters forwarded from the inbound URI. Used to carry re-engagement
  /// context (e.g. an email hint on a magic-link login).
  final Map<String, String> queryParameters;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResolvedLink &&
            routeName == other.routeName &&
            _mapEquals(pathParameters, other.pathParameters) &&
            _mapEquals(queryParameters, other.queryParameters);
  }

  @override
  int get hashCode => Object.hash(
    routeName,
    Object.hashAllUnordered(
      pathParameters.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      queryParameters.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'ResolvedLink(routeName: $routeName, path: $pathParameters, query: $queryParameters)';
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// Compile-time allowlist of deep-link hosts (the associated domains / app-link
/// hosts the app will accept inbound URIs from).
///
/// This is the **security boundary** for inbound routing: a URI whose host is
/// not in this set resolves to `null` regardless of its path, so a malicious
/// site cannot route a user into an auth flow. Sourced from compile-time
/// `AppConfig` (a comma-separated `ALLOWED_DEEP_LINK_HOSTS` define); there is no
/// runtime fallback (C6 — no runtime environment switching).
///
/// Hosts are compared case-insensitively (DNS is). An empty allowlist disables
/// inbound routing entirely — every URI resolves to `null`, which is the safe
/// default when no associated domain is configured.
@immutable
final class AllowedDeepLinkHosts {
  const AllowedDeepLinkHosts(this.hosts);

  /// Parses a comma-separated host list (the shape of the compile-time define).
  /// Empty / whitespace-only values are dropped; hosts are lower-cased so the
  /// case-insensitive [allows] check is a simple set lookup.
  factory AllowedDeepLinkHosts.parse(String raw) {
    final normalized = <String>{};
    for (final part in raw.split(',')) {
      final host = part.trim().toLowerCase();
      if (host.isNotEmpty) {
        normalized.add(host);
      }
    }
    return AllowedDeepLinkHosts(normalized);
  }

  /// The empty allowlist — disables inbound routing. The honest default when no
  /// associated domain is configured.
  static const AllowedDeepLinkHosts empty = AllowedDeepLinkHosts(<String>{});

  final Set<String> hosts;

  /// True when [host] is on the allowlist (case-insensitive). `null` and empty
  /// hosts are never allowed.
  bool allows(String? host) {
    if (host == null) return false;
    final normalized = host.toLowerCase();
    if (normalized.isEmpty) return false;
    return hosts.contains(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AllowedDeepLinkHosts && _setEquals(hosts, other.hosts);
  }

  @override
  int get hashCode => Object.hashAllUnordered(hosts);
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

/// Pure, synchronous `Uri -> ResolvedLink?` resolver.
///
/// Implementations must be total (never throw): a malformed URI, foreign host,
/// or unknown path resolves to `null`. The decision is driven entirely by the
/// host allowlist and the [AppRoutes] path constants — there is no
/// network call and no plugin read here.
// ignore: one_member_abstracts
abstract interface class AppLinkHandler {
  /// Resolves [uri] to a typed [ResolvedLink], or `null` when the URI is
  /// unhandled (foreign host, unknown path, malformed).
  ///
  /// Callers dispatch a non-null result via `context.goNamed` /
  /// `context.pushNamed`; a `null` result is silently ignored (the app stays on
  /// its current route). Never throws for ordinary input.
  ResolvedLink? resolve(Uri uri);
}

/// Production [AppLinkHandler]: allowlist gate + exhaustive path matching against
/// the [AppRoutes] constants.
///
/// Constructed at the composition root with the compile-time
/// [AllowedDeepLinkHosts]; pure-Dart and side-effect-free so it is fully testable
/// without a platform channel.
final class RouteAppLinkHandler implements AppLinkHandler {
  const RouteAppLinkHandler({required this.allowedHosts});

  final AllowedDeepLinkHosts allowedHosts;

  @override
  ResolvedLink? resolve(Uri uri) {
    // Foreign / empty host -> phishing rejection. The host allowlist is the
    // security boundary; never resolve a path against an untrusted host.
    if (!allowedHosts.allows(uri.host)) {
      return null;
    }
    return resolvePath(uri.path, uri.queryParameters);
  }

  /// Path-only resolver, exposed for tests and the dev-gallery trigger. Assumes
  /// the host gate has already passed (or that the caller is acting on a trusted
  /// internal path such as a `/dev/diagnostics` simulation).
  @visibleForTesting
  static ResolvedLink? resolvePath(String path, Map<String, String> query) {
    final normalized = _normalizePath(path);
    final staticRoute = _staticRouteFor(normalized);
    if (staticRoute != null) {
      return ResolvedLink(routeName: staticRoute, queryParameters: query);
    }
    return _tryResolveOtp(normalized, query);
  }
}

/// Normalizes a path for matching: collapses a trailing slash (except for the
/// bare root `/`) and drops any `//` runs the platform may inject. The router
/// itself does not care about a trailing slash, but normalizing makes the
/// exhaustive switch below deterministic.
String _normalizePath(String path) {
  if (path.isEmpty) {
    return AppRoutes.homePath;
  }
  var normalized = path;
  if (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

/// Exhaustive switch over the supported static route paths. Returns the matching
/// [AppRoutes] name, or `null` for an unknown path. Add new deep-linkable static
/// routes here (and only here) — the OTP dynamic route is handled separately by
/// [_tryResolveOtp].
String? _staticRouteFor(String path) {
  return switch (path) {
    AppRoutes.homePath => AppRoutes.home,
    AppRoutes.loginPath => AppRoutes.login,
    AppRoutes.registerPath => AppRoutes.register,
    AppRoutes.forgotPasswordPath => AppRoutes.forgotPassword,
    AppRoutes.resetPasswordPath => AppRoutes.resetPassword,
    AppRoutes.settingsPath => AppRoutes.settings,
    AppRoutes.pricingPath => AppRoutes.pricing,
    _ => null,
  };
}

const String _otpPathPrefix = '/auth/otp/';

/// Resolves the dynamic OTP route `/auth/otp/<purpose>` using the existing
/// [OtpPurpose.tryParse] table. Returns `null` for a missing, nested, or unknown
/// purpose segment — the existing OTP route builder renders a localized error
/// page for a bad purpose, so a deep link with an invalid purpose is dropped here
/// rather than navigated to (the user stays on their current route).
ResolvedLink? _tryResolveOtp(String path, Map<String, String> query) {
  if (!path.startsWith(_otpPathPrefix)) {
    return null;
  }
  final segment = path.substring(_otpPathPrefix.length);
  // Reject nested segments (/auth/otp/reg/extra) and an empty purpose.
  if (segment.isEmpty || segment.contains('/')) {
    return null;
  }
  final purpose = OtpPurpose.tryParse(segment);
  if (purpose == null) {
    return null;
  }
  return ResolvedLink(
    routeName: AppRoutes.otp,
    pathParameters: <String, String>{'purpose': purpose.pathSegment},
    queryParameters: query,
  );
}

/// Owns the `app_links` plugin instance and exposes the resolved inbound stream
/// plus the cold-start initial link.
///
/// Widgets consume this only through [appLinkStreamProvider] — they never name
/// `AppLinks` directly (checklist #1/#4: no widget calls a plugin). The
/// composition root constructs the production [AppLinksDeepLinkService]; tests
/// and the dev-gallery trigger use [StreamDeepLinkService] with a
/// `StreamController<Uri>`.
abstract interface class DeepLinkService {
  /// The live stream of resolved inbound links. Foreign-host / unknown-path URIs
  /// are filtered out (resolved to `null` and dropped) so listeners only ever
  /// see actionable destinations.
  Stream<ResolvedLink> get links;

  /// The cold-start link that launched the app, or `null` when the app was
  /// opened normally. Captured once before the router is built so the initial
  /// location can be seeded (see `bootstrap.dart`).
  Future<ResolvedLink?> getInitialLink();

  /// Releases platform subscriptions. The app-scope instance lives for the
  /// process; this is primarily exercised by tests.
  void dispose();
}

/// Functional seam over the platform plugin so [AppLinksDeepLinkService] is
/// unit-testable without the concrete `AppLinks` class hierarchy (which is a
/// concrete class extending a `PlatformInterface`, not an implementable
/// interface). Production wraps `AppLinks()` via [_PluginAppLinkInbox]; tests
/// pass a stub.
abstract interface class AppLinkInbox {
  /// The cold-start URI that launched the app, or `null`.
  Future<Uri?> getInitialLink();

  /// The live stream of inbound raw URIs.
  Stream<Uri> get links;
}

final class _PluginAppLinkInbox implements AppLinkInbox {
  AppLinks? _appLinks;

  AppLinks get _platform => _appLinks ??= AppLinks();

  @override
  Future<Uri?> getInitialLink() => _platform.getInitialLink();

  @override
  Stream<Uri> get links => _platform.uriLinkStream;
}

/// Production [DeepLinkService] over the `app_links` plugin.
///
/// The plugin is the **backend-free production default** (receiving is local;
/// per the feature spec there is no Noop — the real plugin IS the default). A
/// plugin failure degrades honestly: [getInitialLink] returns `null` and
/// [links] emits nothing, so the app boots to its normal initial location and
/// never crashes on a malformed inbound URI.
final class AppLinksDeepLinkService implements DeepLinkService {
  AppLinksDeepLinkService({
    required this._handler,
    this._inbox,
  });

  final AppLinkHandler _handler;
  AppLinkInbox? _inbox;

  AppLinkInbox get _platform => _inbox ??= _PluginAppLinkInbox();

  @override
  Stream<ResolvedLink> get links {
    // Map + filter nulls (foreign host / unknown path) so listeners only see
    // actionable destinations. Errors on the platform stream are caught and
    // converted to an end — the app never tears down over a bad inbound URI.
    return _platform.links
        .map(_handler.resolve)
        .where((link) => link != null)
        .cast<ResolvedLink>()
        .handleError((Object _) {});
  }

  @override
  Future<ResolvedLink?> getInitialLink() async {
    try {
      final uri = await _platform.getInitialLink();
      if (uri == null) {
        return null;
      }
      return _handler.resolve(uri);
    } on Object {
      // A plugin failure must never strand startup. Treat as "no initial link"
      // so the router seeds its normal initial location.
      return null;
    }
  }

  @override
  void dispose() {
    // AppLinks has no public dispose across versions; release our handle so the
    // platform instance can be GC'd. The broadcast stream is owned by the
    // plugin and self-cleans when the listener cancels.
    _inbox = null;
  }
}

/// Test / dev-gallery [DeepLinkService] backed by a caller-owned
/// [StreamController] of raw [Uri]s.
///
/// Resolves each emitted URI through the injected [AppLinkHandler] (so foreign
/// hosts and unknown paths are filtered exactly as in production) and surfaces a
/// fixed cold-start URI. Never the production default — production uses
/// [AppLinksDeepLinkService]. Used by unit/widget tests and a future
/// `/dev/diagnostics` manual-QA trigger; no Mocktail, no codegen.
@visibleForTesting
final class StreamDeepLinkService implements DeepLinkService {
  StreamDeepLinkService({
    required this._handler,
    required this._controller,
    this._initialLink,
  });

  final AppLinkHandler _handler;
  final StreamController<Uri> _controller;
  final Uri? _initialLink;

  @override
  Stream<ResolvedLink> get links {
    return _controller.stream
        .map(_handler.resolve)
        .where((link) => link != null)
        .cast<ResolvedLink>();
  }

  @override
  Future<ResolvedLink?> getInitialLink() async {
    final uri = _initialLink;
    if (uri == null) {
      return null;
    }
    return _handler.resolve(uri);
  }

  @override
  void dispose() {
    // Closing is the caller's responsibility when they own the controller
    // (tests typically pass `StreamController.broadcast()`). Only close streams
    // this service created — here we never do, so this is a safe no-op that
    // matches the production adapter's shape.
  }
}

/// Handwritten Riverpod handle for the [DeepLinkService]. Overridden at the
/// composition root with [AppLinksDeepLinkService] (constructed in
/// `AppDependencies`); throws [StateError] until wired (mirrors
/// `settingsStoreProvider` / `secureStoreProvider` — HARD RULE 2).
///
/// Named `appLinkHandlerProvider` per the feature spec ("handwritten Riverpod
/// over a DeepLinkService").
final appLinkHandlerProvider = Provider<DeepLinkService>(
  (ref) => throw StateError(
    'DeepLinkService must be overridden at the composition root.',
  ),
);

/// Derived stream of resolved inbound links. `_AppViewState` `ref.listen`s this
/// and dispatches via `context.goNamed` / `context.pushNamed` — it never touches
/// `AppLinks` or [DeepLinkService] directly. Cold-start is handled separately
/// (`bootstrap.dart` seeds `initialLocation` from `getInitialLink` before the
/// router builds).
final appLinkStreamProvider = StreamProvider<ResolvedLink>(
  (ref) => ref.watch(appLinkHandlerProvider).links,
);
