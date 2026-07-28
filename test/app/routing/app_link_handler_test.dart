import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';

void main() {
  group('AllowedDeepLinkHosts', () {
    test('allows a listed host case-insensitively', () {
      const hosts = AllowedDeepLinkHosts(<String>{'app.example.com'});
      expect(hosts.allows('app.example.com'), isTrue);
      expect(hosts.allows('APP.Example.com'), isTrue);
      expect(hosts.allows('other.example.com'), isFalse);
    });

    test('rejects null and empty hosts', () {
      const hosts = AllowedDeepLinkHosts(<String>{'app.example.com'});
      expect(hosts.allows(null), isFalse);
      expect(hosts.allows(''), isFalse);
    });

    test('empty allowlist disables inbound routing', () {
      const hosts = AllowedDeepLinkHosts.empty;
      expect(hosts.allows('app.example.com'), isFalse);
    });

    test('parse splits, trims, and lower-cases a comma list', () {
      final hosts = AllowedDeepLinkHosts.parse(
        ' app.example.com , AUTH.example.com ,, ',
      );
      expect(hosts.hosts, {'app.example.com', 'auth.example.com'});
      expect(hosts.allows('APP.Example.com'), isTrue);
    });

    test('parse of an empty string yields the empty allowlist', () {
      expect(AllowedDeepLinkHosts.parse('').hosts, isEmpty);
      expect(AllowedDeepLinkHosts.parse(' , , ').hosts, isEmpty);
    });

    test('value equality', () {
      const a = AllowedDeepLinkHosts(<String>{'a.example', 'b.example'});
      const b = AllowedDeepLinkHosts(<String>{'b.example', 'a.example'});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ResolvedLink', () {
    test('value equality across param order', () {
      const a = ResolvedLink(
        routeName: AppRoutes.login,
        queryParameters: {'a': '1', 'b': '2'},
      );
      const b = ResolvedLink(
        routeName: AppRoutes.login,
        queryParameters: {'b': '2', 'a': '1'},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('unequal when routeName differs', () {
      const a = ResolvedLink(routeName: AppRoutes.login);
      const b = ResolvedLink(routeName: AppRoutes.home);
      expect(a == b, isFalse);
    });
  });

  group('RouteAppLinkHandler.resolve', () {
    const handler = RouteAppLinkHandler(
      allowedHosts: AllowedDeepLinkHosts(<String>{'app.example.com'}),
    );

    Uri uri(String s) => Uri.parse(s);

    final staticCases = <(String, String)>[
      ('https://app.example.com/', AppRoutes.home),
      ('https://app.example.com/auth/login', AppRoutes.login),
      ('https://app.example.com/auth/register', AppRoutes.register),
      ('https://app.example.com/auth/forgot-password', AppRoutes.forgotPassword),
      ('https://app.example.com/auth/reset-password', AppRoutes.resetPassword),
      ('https://app.example.com/settings', AppRoutes.settings),
      ('https://app.example.com/pricing', AppRoutes.pricing),
    ];

    for (final (raw, expectedRoute) in staticCases) {
      test('$raw -> $expectedRoute', () {
        final link = handler.resolve(uri(raw));
        expect(link, isNotNull);
        expect(link!.routeName, expectedRoute);
        expect(link.pathParameters, isEmpty);
      });
    }

    test('forwards query parameters on a static route', () {
      final link = handler.resolve(
        uri('https://app.example.com/auth/login?email=foo%40bar.com'),
      );
      expect(link, isNotNull);
      expect(link!.routeName, AppRoutes.login);
      expect(link.queryParameters, {'email': 'foo@bar.com'});
    });

    test('trailing slash collapses to the same route', () {
      final withSlash = handler.resolve(uri('https://app.example.com/auth/login/'));
      expect(withSlash, isNotNull);
      expect(withSlash!.routeName, AppRoutes.login);
    });

    test('OTP registration purpose resolves with path param', () {
      final link = handler.resolve(
        uri('https://app.example.com/auth/otp/registration'),
      );
      expect(link, isNotNull);
      expect(link!.routeName, AppRoutes.otp);
      expect(link.pathParameters, {'purpose': OtpPurpose.registration.pathSegment});
    });

    test('OTP password-reset purpose resolves with path param', () {
      final link = handler.resolve(
        uri('https://app.example.com/auth/otp/password-reset'),
      );
      expect(link, isNotNull);
      expect(link!.routeName, AppRoutes.otp);
      expect(link.pathParameters, {'purpose': OtpPurpose.passwordReset.pathSegment});
    });

    test('OTP route forwards query parameters alongside the purpose', () {
      final link = handler.resolve(
        uri('https://app.example.com/auth/otp/password-reset?continue=1'),
      );
      expect(link, isNotNull);
      expect(link!.pathParameters, {'purpose': 'password-reset'});
      expect(link.queryParameters, {'continue': '1'});
    });

    test('unknown OTP purpose segment -> null (ignored, not navigated)', () {
      expect(
        handler.resolve(uri('https://app.example.com/auth/otp/not-a-purpose')),
        isNull,
      );
    });

    test('OTP path missing the purpose segment -> null', () {
      expect(
        handler.resolve(uri('https://app.example.com/auth/otp/')),
        isNull,
      );
    });

    test('nested OTP segment -> null', () {
      expect(
        handler.resolve(
          uri('https://app.example.com/auth/otp/registration/extra'),
        ),
        isNull,
      );
    });

    test('unknown path on an allowed host -> null', () {
      expect(
        handler.resolve(uri('https://app.example.com/somewhere/unknown')),
        isNull,
      );
    });

    test('foreign host (phishing) -> null regardless of path', () {
      expect(
        handler.resolve(uri('https://evil.example.com/auth/login')),
        isNull,
      );
      // Even a host that shares a parent domain is rejected: the match is exact.
      expect(
        handler.resolve(uri('https://sub.app.example.com/auth/login')),
        isNull,
      );
    });

    test('host-less custom-scheme URI -> null (host allowlist is the gate)', () {
      expect(handler.resolve(uri('starter://auth/login')), isNull);
    });

    test('empty allowlist rejects every URI', () {
      const rejecting = RouteAppLinkHandler(allowedHosts: AllowedDeepLinkHosts.empty);
      expect(
        rejecting.resolve(uri('https://app.example.com/auth/login')),
        isNull,
      );
    });
  });

  group('RouteAppLinkHandler.resolvePath (trusted internal path)', () {
    test('resolves a known path without a host check', () {
      final link = RouteAppLinkHandler.resolvePath('/auth/login', {});
      expect(link?.routeName, AppRoutes.login);
    });

    test('unknown path -> null', () {
      final link = RouteAppLinkHandler.resolvePath('/nope', {});
      expect(link, isNull);
    });
  });

  group('StreamDeepLinkService', () {
    late RouteAppLinkHandler handler;
    late StreamController<Uri> controller;

    setUp(() {
      handler = const RouteAppLinkHandler(
        allowedHosts: AllowedDeepLinkHosts(<String>{'app.example.com'}),
      );
      controller = StreamController<Uri>(sync: true);
    });

    tearDown(() {
      // The controller is single-subscription; close()'s returned future only
      // completes once the done event reaches a listener, which these tests
      // never attach. unawaited marks the close fire-and-forget so the test
      // doesn't hang waiting for a non-existent subscriber.
      unawaited(controller.close());
    });

    test('getInitialLink resolves the cold-start URI', () async {
      final service = StreamDeepLinkService(
        handler: handler,
        controller: controller,
        initialLink: Uri.parse('https://app.example.com/auth/login'),
      );
      final link = await service.getInitialLink();
      expect(link?.routeName, AppRoutes.login);
    });

    test('getInitialLink returns null when no cold-start link is present', () async {
      final service = StreamDeepLinkService(
        handler: handler,
        controller: controller,
      );
      expect(await service.getInitialLink(), isNull);
    });

    test('links stream emits resolved destinations and filters foreign hosts', () async {
      final service = StreamDeepLinkService(handler: handler, controller: controller);
      final emitted = <ResolvedLink>[];
      final subscription = service.links.listen(emitted.add);
      controller
        ..add(Uri.parse('https://app.example.com/auth/login?email=a@b'))
        ..add(Uri.parse('https://evil.example.com/auth/login'))
        ..add(Uri.parse('https://app.example.com/auth/otp/password-reset'))
        ..add(Uri.parse('https://app.example.com/unknown'));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      expect(emitted, hasLength(2));
      expect(emitted[0].routeName, AppRoutes.login);
      expect(emitted[0].queryParameters, {'email': 'a@b'});
      expect(emitted[1].routeName, AppRoutes.otp);
      expect(emitted[1].pathParameters, {'purpose': 'password-reset'});
    });

    test('dispose is a safe no-op (does not close the caller-owned controller)', () async {
      StreamDeepLinkService(handler: handler, controller: controller).dispose();
      // The controller is still usable (the test's tearDown closes it).
      controller.add(Uri.parse('https://app.example.com/'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.isClosed, isFalse);
    });
  });

  group('AppLinksDeepLinkService (error path)', () {
    test('getInitialLink swallows a plugin failure and returns null', () async {
      final service = AppLinksDeepLinkService(
        handler: const RouteAppLinkHandler(
          allowedHosts: AllowedDeepLinkHosts(<String>{'app.example.com'}),
        ),
        inbox: _ThrowingInbox(),
      );
      expect(await service.getInitialLink(), isNull);
    });

    test('getInitialLink resolves a valid initial URI', () async {
      final service = AppLinksDeepLinkService(
        handler: const RouteAppLinkHandler(
          allowedHosts: AllowedDeepLinkHosts(<String>{'app.example.com'}),
        ),
        inbox: _StubInbox(
          initial: Uri.parse('https://app.example.com/auth/reset-password'),
        ),
      );
      final link = await service.getInitialLink();
      expect(link?.routeName, AppRoutes.resetPassword);
    });

    test('links filters nulls and forwards resolved links', () async {
      final streamController = StreamController<Uri>(sync: true);
      final service = AppLinksDeepLinkService(
        handler: const RouteAppLinkHandler(
          allowedHosts: AllowedDeepLinkHosts(<String>{'app.example.com'}),
        ),
        inbox: _StubInbox(stream: streamController.stream),
      );
      final emitted = <ResolvedLink>[];
      final subscription = service.links.listen(emitted.add);
      streamController
        ..add(Uri.parse('https://app.example.com/'))
        ..add(Uri.parse('https://evil.example.com/auth/login'))
        ..add(Uri.parse('https://app.example.com/auth/otp/registration'));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await streamController.close();
      expect(emitted, hasLength(2));
      expect(emitted[0].routeName, AppRoutes.home);
      expect(emitted[1].routeName, AppRoutes.otp);
    });
  });
}

/// Minimal fake [AppLinkInbox] that returns a deterministic initial URI and/or a
/// controlled stream. Avoids touching the platform channel in unit tests.
class _StubInbox implements AppLinkInbox {
  _StubInbox({this.initial, this.stream});

  final Uri? initial;
  final Stream<Uri>? stream;

  @override
  Future<Uri?> getInitialLink() async => initial;

  @override
  Stream<Uri> get links => stream ?? const Stream<Uri>.empty();
}

class _ThrowingInbox implements AppLinkInbox {
  @override
  Future<Uri?> getInitialLink() async => throw StateError('plugin unavailable');

  @override
  Stream<Uri> get links => const Stream<Uri>.empty();
}
