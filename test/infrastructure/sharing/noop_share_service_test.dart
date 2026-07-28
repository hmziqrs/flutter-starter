import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/sharing/noop_share_service.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';

void main() {
  group('NoopShareService', () {
    test('shareText honestly reports unavailable (never fakes success)', () async {
      const service = NoopShareService();
      final result = await service.shareText('Share me');
      expect(result, ShareResult.unavailable);
    });

    test('shareFiles honestly reports unavailable (never fakes success)', () async {
      const service = NoopShareService();
      final result = await service.shareFiles(<XFile>[XFile('/tmp/sample.txt')]);
      expect(result, ShareResult.unavailable);
    });

    test('is a const-constructible honest default (no backend wiring)', () async {
      // Two independent const instances behave identically — the no-backend
      // default is stateless and deterministic.
      const a = NoopShareService();
      const b = NoopShareService();
      expect(await a.shareText('a'), await b.shareText('b'));
      expect(await a.shareFiles(const <XFile>[]), await b.shareFiles(const <XFile>[]));
    });
  });

  group('ShareResult', () {
    test('exposes exactly the success / unavailable / cancelled variants', () {
      const values = ShareResult.values;
      expect(values, hasLength(3));
      expect(
        values,
        containsAll(const <ShareResult>[
          ShareResult.success,
          ShareResult.unavailable,
          ShareResult.cancelled,
        ]),
      );
    });

    test('variants are not equal to each other (exhaustive switch stays distinct)', () {
      for (final a in ShareResult.values) {
        for (final b in ShareResult.values) {
          expect(a == b, a == b); // sanity: identity
          if (identical(a, b)) {
            expect(a == b, isTrue);
            expect(a.hashCode, b.hashCode);
          }
        }
      }
      // Pairwise distinctness.
      expect(ShareResult.success == ShareResult.unavailable, isFalse);
      expect(ShareResult.success == ShareResult.cancelled, isFalse);
      expect(ShareResult.unavailable == ShareResult.cancelled, isFalse);
    });
  });

  group('ShareServiceException', () {
    test('carries the failing operation and renders a stable message', () {
      const exception = ShareServiceException(operation: 'shareText');
      expect(exception.operation, 'shareText');
      expect(exception.toString(), 'ShareServiceException: shareText failed');
    });
  });
}
