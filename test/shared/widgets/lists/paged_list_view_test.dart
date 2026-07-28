import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/state/paged_state.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/lists/paged_list_view.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';
import 'package:starter/shared/widgets/states/error_state_view.dart';
import 'package:starter/shared/widgets/states/loading_state_view.dart';

const _emptyTitle = 'No results';
const _emptyBody = 'Try a different query.';
const _errorTitle = 'Search failed';

PagedState<String> _state({
  PagedStateStatus status = PagedStateStatus.idle,
  List<String> items = const [],
  bool hasMore = true,
  int? cursor,
  Object? error,
}) {
  return PagedState<String>(
    items: items,
    status: status,
    hasMore: hasMore,
    cursor: cursor,
    error: error,
  );
}

Widget _harness({required Widget child}) {
  return TranslationProvider(
    child: Builder(
      builder: (context) {
        final localeData = TranslationProvider.of(context);
        final theme = generated.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeData.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          home: Scaffold(body: child),
          builder: (context, built) {
            return Directionality(
              textDirection: localeData.locale == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: FTheme(
                data: theme,
                child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
              ),
            );
          },
        );
      },
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('PagedListView', () {
    testWidgets('renders LoadingStateView while the first page loads', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: PagedListView<String>(
            state: _state(status: PagedStateStatus.loading),
            itemBuilder: (_, item) => Text(item),
            keyOf: (item) => item,
            onLoadNext: () async {},
            onRefresh: () async {},
            emptyTitle: _emptyTitle,
            emptyBody: _emptyBody,
            errorTitle: _errorTitle,
          ),
        ),
      );
      await _pumpFrames(tester);
      expect(find.byType(LoadingStateView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('renders ErrorStateView with retry on a failed first page', (tester) async {
      var refreshCalls = 0;
      await tester.pumpWidget(
        _harness(
          child: PagedListView<String>(
            state: _state(status: PagedStateStatus.error),
            itemBuilder: (_, item) => Text(item),
            keyOf: (item) => item,
            onLoadNext: () async {},
            onRefresh: () async {
              refreshCalls += 1;
            },
            emptyTitle: _emptyTitle,
            emptyBody: _emptyBody,
            errorTitle: _errorTitle,
          ),
        ),
      );
      await _pumpFrames(tester);
      expect(find.byType(ErrorStateView), findsOneWidget);
      // The honest no-backend body is surfaced (defaults to common.notConnected).
      final viewContext = tester.element(find.byType(ErrorStateView));
      expect(find.text(viewContext.t.common.notConnected), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('error-state-view-action')));
      await _pumpFrames(tester);
      expect(refreshCalls, 1);
    });

    testWidgets('renders EmptyStateView when the first page resolves empty', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: PagedListView<String>(
            state: _state(status: PagedStateStatus.ready),
            itemBuilder: (_, item) => Text(item),
            keyOf: (item) => item,
            onLoadNext: () async {},
            onRefresh: () async {},
            emptyTitle: _emptyTitle,
            emptyBody: _emptyBody,
            errorTitle: _errorTitle,
          ),
        ),
      );
      await _pumpFrames(tester);
      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text(_emptyTitle), findsOneWidget);
    });

    testWidgets('renders items with stable ValueKeys derived from keyOf', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: PagedListView<String>(
            state: _state(
              status: PagedStateStatus.ready,
              items: const ['alpha', 'beta', 'gamma'],
            ),
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
            keyOf: (item) => item,
            onLoadNext: () async {},
            onRefresh: () async {},
            emptyTitle: _emptyTitle,
            emptyBody: _emptyBody,
            errorTitle: _errorTitle,
          ),
        ),
      );
      await _pumpFrames(tester);
      expect(find.byKey(const ValueKey('paged-alpha')), findsOneWidget);
      expect(find.byKey(const ValueKey('paged-beta')), findsOneWidget);
      expect(find.byKey(const ValueKey('paged-gamma')), findsOneWidget);
    });

    testWidgets('triggers onLoadNext near scroll end while more pages remain', (tester) async {
      var loadNextCalls = 0;
      final items = [for (var i = 0; i < 20; i += 1) 'item-$i'];
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            height: 400,
            child: PagedListView<String>(
              state: _state(
                status: PagedStateStatus.ready,
                items: items,
                cursor: items.length,
              ),
              itemBuilder: (_, item) => SizedBox(
                height: 80,
                child: Text(item),
              ),
              keyOf: (item) => item,
              onLoadNext: () async {
                loadNextCalls += 1;
              },
              onRefresh: () async {},
              emptyTitle: _emptyTitle,
              emptyBody: _emptyBody,
              errorTitle: _errorTitle,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);
      expect(loadNextCalls, 0);

      // Fling toward the end; the threshold listener should fire onLoadNext.
      await tester.fling(find.byType(ListView), const Offset(0, -2000), 2000);
      await _pumpFrames(tester);
      expect(loadNextCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('does not trigger onLoadNext when hasMore is false', (tester) async {
      var loadNextCalls = 0;
      final items = [for (var i = 0; i < 20; i += 1) 'item-$i'];
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            height: 400,
            child: PagedListView<String>(
              state: _state(
                status: PagedStateStatus.ready,
                items: items,
                hasMore: false,
              ),
              itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
              keyOf: (item) => item,
              onLoadNext: () async {
                loadNextCalls += 1;
              },
              onRefresh: () async {},
              emptyTitle: _emptyTitle,
              emptyBody: _emptyBody,
              errorTitle: _errorTitle,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);
      await tester.fling(find.byType(ListView), const Offset(0, -2000), 2000);
      await _pumpFrames(tester);
      expect(loadNextCalls, 0);
    });
  });
}
