/// Inbound deep-link routing.
///
/// Intercepts native URIs (iOS Universal Links, Android App Links, custom
/// schemes) surfaced by the `app_links` plugin and resolves them to existing
/// `go_router` destinations via the [AppRoutes] name + path constants.
/// Backend-free: the only side effect is navigation — this module only
/// *receives* links, it never issues them.
///
/// The security boundary is the host allowlist ([AllowedDeepLinkHosts]),
/// sourced from compile-time `AppConfig`. A URI whose host is not on the
/// allowlist resolves to `null` (phishing rejection); an unknown path also
/// resolves to `null` (ignored, never an error).
///
/// [AppLinkHandler] is a pure, synchronous `Uri -> ResolvedLink?` resolver
/// with no plugin and no side effects. [DeepLinkService] owns the `AppLinks`
/// plugin instance and exposes the resolved stream + cold-start initial
/// link; widgets read [appLinkStreamProvider] instead of naming `AppLinks`
/// directly. The composition root constructs the real adapter;
/// [appLinkHandlerProvider] throws [StateError] until overridden.
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';

/// Typed result of resolving an inbound deep-link [Uri] against the route
/// table. Carries the target [routeName] plus the `pathParameters` /
/// `queryParameters` needed to dispatch via `context.goNamed` /
/// `context.pushNamed`. Immutable and value-equal so it flows through
/// Riverpod unchanged.
@immutable
final class ResolvedLink {
  const ResolvedLink({
    required this.routeName,
    this.pathParameters = const <String, String>{},
    this.queryParameters = const <String, String>{},
  });

  /// The [AppRoutes] name to navigate to.
  final String routeName;

  /// Path parameters for the target route. Only populated for the OTP route
  /// (`purpose`); static routes use an empty map.
  final Map<String, String> pathParameters;

  /// Query parameters forwarded from the inbound URI.
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

/// Compile-time allowlist of deep-link hosts. This is the security boundary
/// for inbound routing: a URI whose host is not in this set resolves to
/// `null` regardless of its path. Sourced from a comma-separated
/// `ALLOWED_DEEP_LINK_HOSTS` compile-time define; hosts are compared
/// case-insensitively. An empty allowlist disables inbound routing entirely.
@immutable
final class AllowedDeepLinkHosts {
  const AllowedDeepLinkHosts(this.hosts);

  /// Parses a comma-separated host list. Empty/whitespace-only values are
  /// dropped; hosts are lower-cased so [allows] is a simple set lookup.
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

  /// The empty allowlist — disables inbound routing.
  static const AllowedDeepLinkHosts empty = AllowedDeepLinkHosts(<String>{});

  final Set<String> hosts;

  /// True when [host] is on the allowlist (case-insensitive).
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

/// Pure, synchronous `Uri -> ResolvedLink?` resolver. Implementations must be
/// total (never throw): a malformed URI, foreign host, or unknown path
/// resolves to `null`.
// ignore: one_member_abstracts
abstract interface class AppLinkHandler {
  /// Resolves [uri] to a typed [ResolvedLink], or `null` when unhandled
  /// (foreign host, unknown path, malformed). A `null` result is silently
  /// ignored by callers — the app stays on its current route.
  ResolvedLink? resolve(Uri uri);
}

/// Production [AppLinkHandler]: allowlist gate + exhaustive path matching
/// against the [AppRoutes] constants.
final class RouteAppLinkHandler implements AppLinkHandler {
  const RouteAppLinkHandler({required this.allowedHosts});

  final AllowedDeepLinkHosts allowedHosts;

  @override
  ResolvedLink? resolve(Uri uri) {
    // Foreign/empty host -> phishing rejection; never resolve a path against
    // an untrusted host.
    if (!allowedHosts.allows(uri.host)) {
      return null;
    }
    return resolvePath(uri.path, uri.queryParameters);
  }

  /// Path-only resolver, exposed for tests and the dev-gallery trigger. Assumes
  /// the host gate has already passed.
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
/// bare root `/`).
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

/// Exhaustive switch over the supported static route paths. Add new
/// deep-linkable static routes here — the OTP dynamic route is handled
/// separately by [_tryResolveOtp].
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

/// Resolves the dynamic OTP route `/auth/otp/<purpose>`. Returns `null` for a
/// missing, nested, or unknown purpose segment (dropped rather than navigated
/// to; the user stays on their current route).
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
/// Widgets consume this only through [appLinkStreamProvider] — no widget calls
/// the plugin directly.
abstract interface class DeepLinkService {
  /// The live stream of resolved inbound links. Foreign-host / unknown-path
  /// URIs are filtered out so listeners only see actionable destinations.
  Stream<ResolvedLink> get links;

  /// The cold-start link that launched the app, or `null` when opened
  /// normally. Captured once before the router is built (see `bootstrap.dart`).
  Future<ResolvedLink?> getInitialLink();

  /// Releases platform subscriptions.
  void dispose();
}

/// Functional seam over the platform plugin so [AppLinksDeepLinkService] is
/// unit-testable without the concrete `AppLinks` class (a `PlatformInterface`
/// subclass, not an implementable interface). Production wraps `AppLinks()`
/// via [_PluginAppLinkInbox]; tests pass a stub.
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

/// Production [DeepLinkService] over the `app_links` plugin. A plugin failure
/// degrades honestly: [getInitialLink] returns `null` and [links] emits
/// nothing, so the app boots to its normal initial location.
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
    // Errors on the platform stream are caught and converted to an end — the
    // app never tears down over a bad inbound URI.
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
      // A plugin failure must never strand startup.
      return null;
    }
  }

  @override
  void dispose() {
    // AppLinks has no public dispose across versions; release our handle so
    // the platform instance can be GC'd.
    _inbox = null;
  }
}

/// Test / dev-gallery [DeepLinkService] backed by a caller-owned
/// [StreamController] of raw [Uri]s. Resolves each emitted URI through the
/// injected [AppLinkHandler] so foreign hosts and unknown paths are filtered
/// exactly as in production.
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
    // Closing is the caller's responsibility when they own the controller;
    // we never create one, so this is a safe no-op.
  }
}

/// Handwritten Riverpod handle for the [DeepLinkService]. Overridden at the
/// composition root with [AppLinksDeepLinkService]; throws [StateError]
/// until wired.
final appLinkHandlerProvider = Provider<DeepLinkService>(
  (ref) => throw StateError(
    'DeepLinkService must be overridden at the composition root.',
  ),
);

/// Derived stream of resolved inbound links. Cold-start is handled separately
/// (`bootstrap.dart` seeds `initialLocation` from `getInitialLink` before the
/// router builds).
final appLinkStreamProvider = StreamProvider<ResolvedLink>(
  (ref) => ref.watch(appLinkHandlerProvider).links,
);
