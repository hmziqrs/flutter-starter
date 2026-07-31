import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/search/debounced_query_controller.dart';

void main() {
  group('DebouncedQueryController', () {
    test('emits the initial empty query before any input', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        expect(container.read(debouncedQueryProvider), '');
        async.elapse(debounceQueryDuration * 4);
      });
    });

    test('publishes only after the debounce window elapses', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(debouncedQueryProvider.notifier).set('hello');
        expect(container.read(debouncedQueryProvider), '');
        async.elapse(debounceQueryDuration - const Duration(milliseconds: 1));
        expect(container.read(debouncedQueryProvider), '');
        async.elapse(const Duration(milliseconds: 1));
        expect(container.read(debouncedQueryProvider), 'hello');
      });
    });

    test('drops stale values — only the latest within the window publishes', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(debouncedQueryProvider.notifier)..set('a');
        async.elapse(const Duration(milliseconds: 100));
        notifier.set('ab');
        async.elapse(const Duration(milliseconds: 100));
        notifier.set('abc');
        expect(container.read(debouncedQueryProvider), '');
        async.elapse(debounceQueryDuration);
        expect(container.read(debouncedQueryProvider), 'abc');
      });
    });

    test('clear publishes immediately and cancels the pending timer', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(debouncedQueryProvider.notifier)
          ..set('hello')
          ..clear();
        expect(container.read(debouncedQueryProvider), '');
        async.elapse(debounceQueryDuration * 2);
        expect(container.read(debouncedQueryProvider), '');
      });
    });

    test('coalesces rapid input into a single publish', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(debouncedQueryProvider.notifier)..set('one');
        async.elapse(debounceQueryDuration);
        expect(container.read(debouncedQueryProvider), 'one');
        notifier.set('two');
        async.elapse(debounceQueryDuration);
        expect(container.read(debouncedQueryProvider), 'two');
      });
    });

    test('does not republish an identical settled value', () {
      fakeAsync((async) {
        var buildCount = 0;
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(debouncedQueryProvider, (_, _) => buildCount += 1);
        final notifier = container.read(debouncedQueryProvider.notifier)..set('same');
        async.elapse(debounceQueryDuration);
        notifier.set('same');
        async.elapse(debounceQueryDuration);
        expect(container.read(debouncedQueryProvider), 'same');
        expect(buildCount, lessThanOrEqualTo(1));
      });
    });
  });
}
