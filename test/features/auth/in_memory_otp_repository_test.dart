import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/in_memory_otp_repository.dart';
import 'package:starter/features/auth/otp_repository.dart';

void main() {
  group('InMemoryOtpRepository', () {
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
        try {
          await repository.verify(identifier: 'a@b.c', code: '000000');
          fail('verify returned without throwing — the no-backend guard broke.');
        } on OtpRepositoryException {
          // ignored
        }
      });

      test('issue never returns a OtpIssueResult', () async {
        try {
          await repository.issue(purpose: OtpPurpose.registration, identifier: 'a@b.c');
          fail('issue returned without throwing — the no-backend guard broke.');
        } on OtpRepositoryException {
          // ignored
        }
      });
    });
  });

  group('otpRepositoryProvider', () {
    test('throws until the composition root overrides it', () {
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
