import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/experiments/deterministic_experiment_source.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/force_update/remote_config_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/infrastructure/auth/http_auth_client.dart';
import 'package:starter/infrastructure/auth/http_otp_client.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/notifications/http_notifications_registration_client.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';
import 'package:starter/infrastructure/remote_config/remote_config_experiment_source.dart';
import 'package:starter/infrastructure/remote_config/remote_config_feature_flags_source.dart';

import '../infrastructure/hono_server_handle.dart';

void main() {
  final runtime = JsRuntime.resolve();

  group('hono server e2e (real dart:http <-> live JS Hono)', () {
    if (runtime == null) {
      test(
        'skipped: no JS runtime (bun or npx tsx) available',
        () {},
        skip: 'no JS runtime (bun or npx tsx) available on PATH',
      );
      return;
    }

    HonoServerHandle? server;
    late final Uri baseUri;
    late HttpAuthClient authClient;
    late HttpOtpClient otpClient;

    setUpAll(() async {
      final handle = await HonoServerHandle.start(runtime: runtime);
      server = handle;
      baseUri = handle.baseUri;
      final dio = buildAppDio(baseUri);
      authClient = HttpAuthClient(baseUrl: baseUri, dio: dio);
      otpClient = HttpOtpClient(baseUrl: baseUri, dio: dio);
    });

    tearDownAll(() async {
      final handle = server;
      if (handle != null) {
        await handle.close();
      }
    });

    test('remote-config fetch round-trips and parses into typed slices', () async {
      final client = RemoteConfigClient(baseUrl: baseUri);
      final payload = await client.fetch(
        const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      );
      expect(payload, isNotNull, reason: 'fetch must succeed against the live server');
      final parsed = payload!;
      expect(parsed.flags, isNotNull, reason: 'flags slice present');
      expect(parsed.versionPolicy, isNotNull, reason: 'versionPolicy slice present');
      expect(parsed.experiments, isNotNull, reason: 'experiments slice present');
      expect(parsed.revision, '1', reason: 'server serves revision "1"');
    });

    test('feature-flags source loads from the live flags slice', () async {
      const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');
      final source = RemoteConfigFeatureFlagsSource(
        baseUrl: baseUri,
        buildInfo: buildInfo,
      );
      final flags = await source.load();
      expect(flags, const FeatureFlags.defaults());
    });

    test('version-gate degrades to none when the policy has no storeUrl', () async {
      final store = RemoteConfigVersionGateStore(baseUrl: baseUri);
      final result = await store.check(
        const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      );
      expect(result, const UpdateRequirementNone());
      expect(store.storeUrl, isNull);
    });

    test('experiments source returns an assignment without throwing', () async {
      const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');
      final source = RemoteConfigExperimentSource(
        baseUrl: baseUri,
        buildInfo: buildInfo,
        fallback: DeterministicExperimentSource(store: InMemorySettingsStore()),
      );
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.key, ExperimentKey.paywallLayout);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });

    test(
      'notifications registration client round-trips register/unregister/permission-revoked',
      () async {
        final client = HttpNotificationsRegistrationClient(baseUrl: baseUri);
        await expectLater(
          client.registerToken(token: 'e2e-token', platform: 'ios', deviceId: 'e2e-device'),
          completes,
        );
        await expectLater(client.unregisterToken('e2e-token'), completes);
        await expectLater(
          client.reportPermissionRevoked(deviceId: 'e2e-device'),
          completes,
        );
      },
    );

    var authEmailSeq = 0;
    String authEmail() => 'hono-e2e-${authEmailSeq++}@example.com';

    test('register returns an OtpIssueResult with attemptToken + sms channel', () async {
      final result = await authClient.register(
        credentials: AuthCredentials(email: authEmail(), password: 'Password1'),
        displayName: 'Sam Rivera',
      );
      expect(result.attemptToken, isNotEmpty);
      expect(result.channel, OtpDeliveryChannel.sms);
      expect(result.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('login exchanges credentials for an authenticated session', () async {
      final session = await authClient.login(
        AuthCredentials(email: authEmail(), password: 'Password1'),
      );
      expect(session, isA<AuthAuthenticated>());
      final auth = session as AuthAuthenticated;
      expect(auth.accessToken, isNotEmpty);
      expect(auth.refreshToken, isNotEmpty);
      expect(auth.userId, isNotEmpty);
      expect(auth.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('registration verify with the dev code returns a valid, non-null session', () async {
      final email = authEmail();
      await authClient.register(
        credentials: AuthCredentials(email: email, password: 'Password1'),
        displayName: 'Sam Rivera',
      );
      await otpClient.issue(purpose: OtpPurpose.registration, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isA<AuthAuthenticated>());
      expect(result.session!.accessToken, isNotEmpty);
      expect(result.session!.refreshToken, isNotEmpty);
      expect(result.session!.userId, isNotEmpty);
    });

    test('a non-registration verify returns valid with a null session', () async {
      final email = authEmail();
      await otpClient.issue(purpose: OtpPurpose.mfa, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isNull, reason: 'mfa purpose issues no session tokens');
    });

    test('refresh rotates the token and inherits userId', () async {
      final email = authEmail();
      final session = await authClient.login(AuthCredentials(email: email, password: 'Password1'));
      final refreshed = await authClient.refresh(session);
      expect(refreshed, isA<AuthAuthenticated>());
      final auth = refreshed as AuthAuthenticated;
      final prior = session as AuthAuthenticated;
      expect(auth.accessToken, isNotEmpty);
      expect(auth.refreshToken, isNot(prior.refreshToken));
      expect(auth.userId, prior.userId, reason: 'userId is inherited across rotations');
    });

    test('logout returns anonymous', () async {
      final email = authEmail();
      final session = await authClient.login(AuthCredentials(email: email, password: 'Password1'));
      expect(await authClient.logout(session), isA<AuthAnonymous>());
    });

    test('honest-degradation: an unreachable backend yields null, never throws', () async {
      final badClient = RemoteConfigClient(
        baseUrl: Uri.parse('http://127.0.0.1:1'),
        timeout: const Duration(milliseconds: 500),
      );
      final payload = await badClient.fetch(
        const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      );
      expect(payload, isNull, reason: 'RemoteConfigClient must degrade to null (C2)');
    });
  });
}
