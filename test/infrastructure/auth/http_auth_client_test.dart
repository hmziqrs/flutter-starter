import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/infrastructure/auth/http_auth_client.dart';
import 'package:starter/infrastructure/auth/http_otp_client.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

import '../hono_server_handle.dart';

void main() {
  final runtime = JsRuntime.resolve();
  if (runtime == null) {
    test(
      'skipped: no JS runtime (bun or npx tsx) available',
      () {},
      skip: 'no JS runtime (bun or npx tsx) available on PATH',
    );
    return;
  }

  group('HttpAuthClient + HttpOtpClient (real dart:io <-> live Hono)', () {
    late HonoServerHandle server;
    late HttpAuthClient authClient;
    late HttpOtpClient otpClient;

    var emailSeq = 0;
    String uniqueEmail() => 'auth-${emailSeq++}@e2e.test';

    setUpAll(() async {
      server = await HonoServerHandle.start(runtime: runtime);
      final dio = buildAppDio(server.baseUri);
      authClient = HttpAuthClient(baseUrl: server.baseUri, dio: dio);
      otpClient = HttpOtpClient(baseUrl: server.baseUri, dio: dio);
    });

    tearDownAll(() => server.close());

    test('register returns an OtpIssueResult with attemptToken + sms channel', () async {
      final result = await authClient.register(
        credentials: AuthCredentials(email: uniqueEmail(), password: 'hunter2'),
        displayName: 'Alex Morgan',
      );
      expect(result.attemptToken, isNotEmpty);
      expect(result.channel, OtpDeliveryChannel.sms);
      expect(result.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('login exchanges credentials for an authenticated session', () async {
      final session = await authClient.login(
        AuthCredentials(email: uniqueEmail(), password: 'hunter2'),
      );
      expect(session, isA<AuthAuthenticated>());
      final auth = session as AuthAuthenticated;
      expect(auth.accessToken, isNotEmpty);
      expect(auth.refreshToken, isNotEmpty);
      expect(auth.userId, isNotEmpty);
      expect(auth.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('registration verify with the dev code returns a valid, non-null session', () async {
      final email = uniqueEmail();
      await authClient.register(
        credentials: AuthCredentials(email: email, password: 'hunter2'),
        displayName: 'Alex Morgan',
      );
      await otpClient.issue(purpose: OtpPurpose.registration, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isA<AuthAuthenticated>());
      expect(result.session!.accessToken, isNotEmpty);
      expect(result.session!.refreshToken, isNotEmpty);
      expect(result.session!.userId, isNotEmpty);
    });

    test('verify with a wrong code returns invalid and no session', () async {
      final email = uniqueEmail();
      await otpClient.issue(purpose: OtpPurpose.registration, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '000000');
      expect(result.outcome, OtpVerifyOutcome.invalid);
      expect(result.session, isNull);
    });

    test('a non-registration verify returns valid with a null session', () async {
      final email = uniqueEmail();
      await otpClient.issue(purpose: OtpPurpose.mfa, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isNull, reason: 'mfa purpose issues no session tokens');
    });

    test('passwordReset purpose round-trips (wire value is the hyphenated segment)', () async {
      final email = uniqueEmail();
      final issued = await otpClient.issue(
        purpose: OtpPurpose.passwordReset,
        identifier: email,
      );
      expect(issued.attemptToken, isNotEmpty);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isNull, reason: 'passwordReset issues no session');
    });

    test('resend re-issues under the last known purpose', () async {
      final email = uniqueEmail();
      await otpClient.issue(purpose: OtpPurpose.mfa, identifier: email);
      final resent = await otpClient.resend(identifier: email);
      expect(resent.attemptToken, isNotEmpty);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isNull);
    });

    test('refresh rotates the token and inherits userId', () async {
      final email = uniqueEmail();
      final session = await authClient.login(AuthCredentials(email: email, password: 'hunter2'));
      final refreshed = await authClient.refresh(session);
      expect(refreshed, isA<AuthAuthenticated>());
      final auth = refreshed as AuthAuthenticated;
      final prior = session as AuthAuthenticated;
      expect(auth.accessToken, isNotEmpty);
      expect(auth.refreshToken, isNot(prior.refreshToken));
      expect(auth.userId, prior.userId, reason: 'userId is inherited across rotations');
    });

    test('logout returns anonymous', () async {
      final email = uniqueEmail();
      final session = await authClient.login(AuthCredentials(email: email, password: 'hunter2'));
      final result = await authClient.logout(session);
      expect(result, isA<AuthAnonymous>());
    });

    test('an unreachable server surfaces AuthException.notConnected', () async {
      final dead = await _deadAddress();
      final bad = HttpAuthClient(baseUrl: dead, dio: buildAppDio(dead));
      await expectLater(
        bad.login(const AuthCredentials(email: 'no@where.test', password: 'hunter2')),
        throwsA(
          isA<AuthException>().having((e) => e.kind, 'kind', AuthFailureKind.notConnected),
        ),
      );
    });

    test('an unreachable server surfaces OtpRepositoryException.notConnected', () async {
      final dead = await _deadAddress();
      final bad = HttpOtpClient(baseUrl: dead, dio: buildAppDio(dead));
      await expectLater(
        bad.issue(purpose: OtpPurpose.registration, identifier: 'no@where.test'),
        throwsA(
          isA<OtpRepositoryException>().having(
            (e) => e.kind,
            'kind',
            OtpFailureKind.notConnected,
          ),
        ),
      );
    });
  });
}

Future<Uri> _deadAddress() async {
  final sink = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = sink.port;
  await sink.close();
  return Uri.parse('http://${InternetAddress.loopbackIPv4.address}:$port');
}
