import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/state/paged_state.dart';
import 'package:starter/shared/state/paged_state_notifier.dart';

final class _ScriptedPagedNotifier extends PagedStateNotifierBase<int> {
  _ScriptedPagedNotifier(this.fetcher);

  @override
  final PageFetcher<int> fetcher;
}

PageFetcher<int> _sequenced({
  required int total,
  required int pageSize,
  int? failOn,
}) {
  return (cursor) async {
    final offset = cursor ?? 0;
    if (failOn case final fail? when fail == offset) {
      throw PagedFetchException.notConnected();
    }
    final page = <int>[
      for (var i = offset; i < (offset + pageSize) && i < total; i += 1) i,
    ];
    final next = offset + page.length;
    return PagedResult<int>(
      items: page,
      nextCursor: next < total ? next : null,
    );
  };
}

ProviderContainer _container(PageFetcher<int> fetcher) {
  final container = ProviderContainer(
    overrides: [
      _testPagedProvider.overrideWith(() => _ScriptedPagedNotifier(fetcher)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

final _testPagedProvider = NotifierProvider<_ScriptedPagedNotifier, PagedState<int>>(
  () => _ScriptedPagedNotifier(_sequenced(total: 0, pageSize: 1)),
);

void main() {
  group('PagedState', () {
    test('isEmpty is false until ready, then true for an empty ready page', () {
      const idle = PagedState<String>();
      expect(idle.isEmpty, isFalse);
      expect(idle.status, PagedStateStatus.idle);
      const readyEmpty = PagedState<String>(status: PagedStateStatus.ready);
      expect(readyEmpty.isEmpty, isTrue);
    });

    test('value equality covers items, status, cursor, hasMore, error', () {
      const a = PagedState<int>(items: [1, 2], status: PagedStateStatus.ready);
      const b = PagedState<int>(items: [1, 2], status: PagedStateStatus.ready);
      const c = PagedState<int>(items: [1, 3], status: PagedStateStatus.ready);
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('PagedStateNotifierBase', () {
    test('loadNext transitions idle -> loadingNext -> ready with appended items', () async {
      final container = _container(_sequenced(total: 20, pageSize: 8));
      final controller = container.read(_testPagedProvider.notifier);
      expect(container.read(_testPagedProvider).status, PagedStateStatus.idle);
      await controller.loadNext();
      final afterFirst = container.read(_testPagedProvider);
      expect(afterFirst.status, PagedStateStatus.ready);
      expect(afterFirst.items, List.generate(8, (i) => i));
      expect(afterFirst.hasMore, isTrue);
      expect(afterFirst.cursor, 8);
    });

    test('appends subsequent pages and stops when the source ends', () async {
      final container = _container(_sequenced(total: 20, pageSize: 8));
      final controller = container.read(_testPagedProvider.notifier);
      await controller.loadNext();
      await controller.loadNext();
      await controller.loadNext();
      final state = container.read(_testPagedProvider);
      expect(state.items, List.generate(20, (i) => i));
      expect(state.hasMore, isFalse);
      expect(state.cursor, isNull);
    });

    test('loadNext is a no-op once hasMore is false', () async {
      final container = _container(_sequenced(total: 3, pageSize: 8));
      final controller = container.read(_testPagedProvider.notifier);
      await controller.loadNext();
      final first = container.read(_testPagedProvider);
      expect(first.items, [0, 1, 2]);
      expect(first.hasMore, isFalse);
      await controller.loadNext();
      expect(container.read(_testPagedProvider), first);
    });

    test('concurrent loadNext calls do not double-fetch', () async {
      final container = _container(_sequenced(total: 20, pageSize: 8));
      final controller = container.read(_testPagedProvider.notifier);
      await Future.wait<void>([controller.loadNext(), controller.loadNext()]);
      expect(container.read(_testPagedProvider).items, List.generate(8, (i) => i));
    });

    test('refresh clears and reloads page one', () async {
      final container = _container(_sequenced(total: 20, pageSize: 8));
      final controller = container.read(_testPagedProvider.notifier);
      await controller.loadNext();
      await controller.loadNext();
      expect(container.read(_testPagedProvider).items.length, 16);
      await controller.refresh();
      final state = container.read(_testPagedProvider);
      expect(state.items, List.generate(8, (i) => i));
      expect(state.status, PagedStateStatus.ready);
    });

    test('captures a fetch failure as a typed error and surfaces notConnected', () async {
      final container = _container(
        _sequenced(total: 20, pageSize: 8, failOn: 8),
      );
      final controller = container.read(_testPagedProvider.notifier);
      await controller.loadNext();
      await controller.loadNext();
      final state = container.read(_testPagedProvider);
      expect(state.status, PagedStateStatus.error);
      expect(state.error, isA<PagedFetchException>());
      expect(
        (state.error! as PagedFetchException).kind,
        PagedFetchFailureKind.notConnected,
      );
      expect(state.items, List.generate(8, (i) => i));
    });

    test('reset returns the notifier to the idle seed', () async {
      final container = _container(_sequenced(total: 20, pageSize: 8));
      final controller = container.read(_testPagedProvider.notifier);
      await controller.loadNext();
      controller.reset();
      final state = container.read(_testPagedProvider);
      expect(state.status, PagedStateStatus.idle);
      expect(state.items, isEmpty);
      expect(state.cursor, isNull);
    });
  });

  group('noopPageFetcher', () {
    test('throws notConnected on every call', () async {
      final fetcher = noopPageFetcher<String>();
      await expectLater(
        fetcher(null),
        throwsA(
          isA<PagedFetchException>().having(
            (e) => e.kind,
            'kind',
            PagedFetchFailureKind.notConnected,
          ),
        ),
      );
    });

    test('a notifier backed by it surfaces the error state', () async {
      final container = _container(noopPageFetcher<int>());
      final controller = container.read(_testPagedProvider.notifier);
      await controller.loadNext();
      final state = container.read(_testPagedProvider);
      expect(state.status, PagedStateStatus.error);
      expect(state.error, isA<PagedFetchException>());
      expect(state.items, isEmpty);
    });
  });
}
