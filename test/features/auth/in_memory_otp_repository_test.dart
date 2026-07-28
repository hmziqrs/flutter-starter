import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/in_memory_otp_repository.dart';
import 'package:starter/features/auth/otp_repository.dart';

void main() {
  group('InMemoryOtpRepository', () {
    // The no-backend default is stateless, so a single const instance exercises
    // every path. Constructed in AppDependencies.production until an endpoint is
    // configured.
    const repository = InMemoryOtpRepository();

    group('no-backend honest-unavailable contract (C2)', () {
      test('issue surfaces OtpRepositoryException.notConnected', () async {
        await expectLater(
          repository.issue(
            purpose: OtpPurpose.registration,
            identifier: 'user@example.com',
          ),
          throwsA(
            isA<OtpRepositoryException>().having(
              (e) => e.kind,
              'kind',
              OtpFailureKind.notConnected,
            ),
          ),
        );
      });

      test('verify surfaces OtpRepositoryException.notConnected', () async {
        await expectLater(
          repository.verify(identifier: 'user@example.com', code: '123456'),
          throwsA(
            isA<OtpRepositoryException>().having(
              (e) => e.kind,
              'kind',
              OtpFailureKind.notConnected,
            ),
          ),
        );
      });

      test('resend surfaces OtpRepositoryException.notConnected', () async {
        await expectLater(
          repository.resend(identifier: 'user@example.com'),
          throwsA(
            isA<OtpRepositoryException>().having(
              (e) => e.kind,
              'kind',
              OtpFailureKind.notConnected,
            ),
          ),
        );
      });

      test('issue throws for every purpose (mfa included once routed)', () async {
        // registration + passwordReset are the today-existing purposes; the mfa
        // arm is added by the described otp_purpose.dart edit. The point of this
        // test is that no purpose slips past the no-backend guard.
        for (final purpose in OtpPurpose.values) {
          await expectLater(
            repository.issue(purpose: purpose, identifier: 'a@b.c'),
            throwsA(isA<OtpRepositoryException>()),
          );
        }
      });
    });

    group('never fakes success (guardrail 13)', () {
      test('verify never returns a OtpVerifyResult', () async {
        // A faked `valid` would let a user past MFA with no backend. Assert the
        // call throws before any result can be constructed.
        try {
          await repository.verify(identifier: 'a@b.c', code: '000000');
          fail('verify returned without throwing — the no-backend guard broke.');
        } on OtpRepositoryException {
          // expected: the only honest outcome with no backend.
        }
      });

      test('issue never returns a OtpIssueResult', () async {
        try {
          await repository.issue(purpose: OtpPurpose.registration, identifier: 'a@b.c');
          fail('issue returned without throwing — the no-backend guard broke.');
        } on OtpRepositoryException {
          // expected.
        }
      });
    });
  });

  group('otpRepositoryProvider', () {
    test('throws until the composition root overrides it', () {
      // Mirrors attemptTrackerProvider / settingsStoreProvider: an unoverridden
      // provider must surface the StateError so a misconfigured build fails loud
      // rather than silently null-decoding.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(otpRepositoryProvider),
        throwsA(
          (Object error) => error.toString().contains('OtpRepository must be overridden'),
        ),
      );
    });

    test('an overridden InMemoryOtpRepository is reachable', () {
      final container = ProviderContainer(
        overrides: [
          otpRepositoryProvider.overrideWithValue(const InMemoryOtpRepository()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(otpRepositoryProvider), isA<InMemoryOtpRepository>());
    });
  });
}
