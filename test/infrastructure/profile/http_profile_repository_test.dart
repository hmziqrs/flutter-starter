// End-to-end coverage for the real HTTP profile adapter
// (`HttpProfileRepository`) against the LIVE in-repo Dart test server
// (`tools/test_server`). No client is stubbed: the adapter speaks to a real
// shelf backend over a loopback socket. The authenticated access token is
// obtained by driving the real registration -> verify flow through the auth +
// OTP HTTP adapters, so the whole path (auth -> OTP -> profile) is exercised
// against one booted server.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/infrastructure/auth/http_auth_client.dart';
import 'package:starter/infrastructure/auth/http_otp_client.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/profile/http_profile_repository.dart';

import '../test_server_handle.dart';

void main() {
  group('HttpProfileRepository (real dart:io <-> live shelf)', () {
    late TestServerHandle server;
    late HttpAuthClient authClient;
    late HttpOtpClient otpClient;
    late HttpProfileRepository profileRepo;

    var emailSeq = 0;
    // Each registration creates server-side state; unique emails keep tests
    // independent within the single booted server process.
    String uniqueEmail() => 'profile-${emailSeq++}@e2e.test';

    setUpAll(() async {
      server = await TestServerHandle.start();
      // A single shared Dio (the composition-root shape) is injected into all
      // three adapters so the full auth -> OTP -> profile path runs over Dio.
      final dio = buildAppDio(server.baseUri);
      authClient = HttpAuthClient(baseUrl: server.baseUri, dio: dio);
      otpClient = HttpOtpClient(baseUrl: server.baseUri, dio: dio);
      profileRepo = HttpProfileRepository(baseUrl: server.baseUri, dio: dio);
    });

    tearDownAll(() => server.close());

    /// Drives the full registration -> verify flow and returns the session
    /// issued inline on a successful registration verify. The pending account
    /// is created with [displayName] so the subsequent profile load asserts it.
    Future<AuthAuthenticated> registerAndVerify({
      required String email,
      required String displayName,
    }) async {
      await authClient.register(
        credentials: AuthCredentials(email: email, password: 'hunter2'),
        displayName: displayName,
      );
      await otpClient.issue(purpose: OtpPurpose.registration, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid, reason: 'registration verify must succeed');
      expect(result.session, isA<AuthAuthenticated>(), reason: 'session must be issued');
      return result.session!;
    }

    test('load after register+verify returns the backend-sourced draft', () async {
      final email = uniqueEmail();
      const displayName = 'Alex Morgan';
      final session = await registerAndVerify(email: email, displayName: displayName);

      final draft = await profileRepo.load(accessToken: session.accessToken);
      expect(draft.displayName, displayName);
      expect(draft.email, email);
      // username is the email's local-part per the backend contract.
      expect(draft.username, email.substring(0, email.indexOf('@')));
      // bio starts empty on a freshly registered account.
      expect(draft.bio, '');
    });

    test('save updates displayName + bio and the change persists', () async {
      final email = uniqueEmail();
      final session = await registerAndVerify(email: email, displayName: 'Old Name');

      final saved = await profileRepo.save(
        accessToken: session.accessToken,
        draft: const ProfileDraft.defaults().copyWith(displayName: 'New Name', bio: 'Updated bio'),
      );
      expect(saved.displayName, 'New Name');
      expect(saved.bio, 'Updated bio');

      // Re-load to confirm the write persisted server-side.
      final reloaded = await profileRepo.load(accessToken: session.accessToken);
      expect(reloaded.displayName, 'New Name');
      expect(reloaded.bio, 'Updated bio');
    });

    test('save can clear bio to empty string', () async {
      final email = uniqueEmail();
      final session = await registerAndVerify(email: email, displayName: 'Bio Tester');

      // Set a bio first, then clear it.
      await profileRepo.save(
        accessToken: session.accessToken,
        draft: const ProfileDraft.defaults().copyWith(bio: 'temporary'),
      );
      final cleared = await profileRepo.save(
        accessToken: session.accessToken,
        draft: const ProfileDraft.defaults().copyWith(bio: ''),
      );
      expect(cleared.bio, '');
    });

    test('a bad access token surfaces ProfileException.notConnected', () async {
      await expectLater(
        profileRepo.load(accessToken: 'not-a-real-token'),
        throwsA(
          isA<ProfileException>().having(
            (e) => e.kind,
            'kind',
            ProfileFailureKind.notConnected,
          ),
        ),
      );
    });

    test('an unreachable server surfaces ProfileException.notConnected', () async {
      final dead = await _deadAddress();
      final bad = HttpProfileRepository(baseUrl: dead, dio: buildAppDio(dead));
      await expectLater(
        bad.load(accessToken: 'anything'),
        throwsA(
          isA<ProfileException>().having(
            (e) => e.kind,
            'kind',
            ProfileFailureKind.notConnected,
          ),
        ),
      );
    });
  });
}

/// Resolves an address guaranteed to refuse connections (bind, read, close).
/// Mirrors the pattern in `http_notifications_registration_client_test.dart`.
Future<Uri> _deadAddress() async {
  final sink = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = sink.port;
  await sink.close();
  return Uri.parse('http://${InternetAddress.loopbackIPv4.address}:$port');
}
