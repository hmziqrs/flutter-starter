/// Deep-link host allowlist ([AllowedDeepLinkHosts]) is the security boundary: non-allowlisted hosts resolve to null (phishing rejection).
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';

@immutable
final class ResolvedLink {
  const ResolvedLink({
    required this.routeName,
    this.pathParameters = const <String, String>{},
    this.queryParameters = const <String, String>{},
  });

  final String routeName;

  final Map<String, String> pathParameters;

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

@immutable
final class AllowedDeepLinkHosts {
  const AllowedDeepLinkHosts(this.hosts);

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

  static const AllowedDeepLinkHosts empty = AllowedDeepLinkHosts(<String>{});

  final Set<String> hosts;

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

// Single-method seam so deep-link resolvers stay mockable in tests.
// ignore: one_member_abstracts
abstract interface class AppLinkHandler {
  ResolvedLink? resolve(Uri uri);
}

final class RouteAppLinkHandler implements AppLinkHandler {
  const RouteAppLinkHandler({required this.allowedHosts});

  final AllowedDeepLinkHosts allowedHosts;

  @override
  ResolvedLink? resolve(Uri uri) {
    if (!allowedHosts.allows(uri.host)) {
      return null;
    }
    return resolvePath(uri.path, uri.queryParameters);
  }

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

ResolvedLink? _tryResolveOtp(String path, Map<String, String> query) {
  if (!path.startsWith(_otpPathPrefix)) {
    return null;
  }
  final segment = path.substring(_otpPathPrefix.length);
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

abstract interface class DeepLinkService {
  Stream<ResolvedLink> get links;

  Future<ResolvedLink?> getInitialLink();

  void dispose();
}

/// Test seam: concrete `AppLinks` is a `PlatformInterface`, not an implementable interface.
abstract interface class AppLinkInbox {
  Future<Uri?> getInitialLink();

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
      return null;
    }
  }

  @override
  void dispose() {
    // AppLinks has no public dispose across versions; release our handle so the platform instance can be GC'd.
    _inbox = null;
  }
}

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
  void dispose() {}
}

final appLinkHandlerProvider = Provider<DeepLinkService>(
  (ref) => throw StateError(
    'DeepLinkService must be overridden at the composition root.',
  ),
);

final appLinkStreamProvider = StreamProvider<ResolvedLink>(
  (ref) => ref.watch(appLinkHandlerProvider).links,
);
