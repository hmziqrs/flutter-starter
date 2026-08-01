import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/shared/async/run_guarded.dart';

void main() {
  final logger = AppLogger(verbose: true);

  test('returns the action result on success', () async {
    final result = await runGuarded(() async => 42, logger: logger, label: 'ok');
    expect(result, 42);
  });

  test('absorbs a thrown Exception and returns null', () async {
    final result = await runGuarded(
      () async => throw StateError('boom'),
      logger: logger,
      label: 'exception',
    );
    expect(result, isNull);
  });

  test('absorbs a thrown Error subtype and returns null', () async {
    // catch-all must cover Error subtypes too, not just Exception.
    final result = await runGuarded(
      () async => throw ArgumentError('bad'),
      logger: logger,
      label: 'error',
    );
    expect(result, isNull);
  });

  test('does not propagate failures to the caller', () async {
    Object? caught;
    try {
      await runGuarded(
        () async => throw RangeError('out'),
        logger: logger,
        label: 'no-propagate',
      );
    } on Object catch (error) {
      caught = error;
    }
    expect(caught, isNull);
  });

  test('preserves a typed result type through the nullable return', () async {
    final result = await runGuarded<String>(
      () async => 'value',
      logger: logger,
      label: 'typed',
    );
    expect(result, 'value');
  });
}
