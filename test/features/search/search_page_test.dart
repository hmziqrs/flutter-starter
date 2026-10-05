import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/search/debounced_query_controller.dart';
import 'package:starter/features/search/search_corpus.dart';
import 'package:starter/features/search/search_page.dart';
import 'package:starter/features/search/search_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cached_future_provider.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

import '../../infrastructure/connectivity/fake_connectivity_service.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required Widget child}) {
  return TranslationProvider(
    child: ProviderScope(
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
                  child: FToaster(
                    child: FTooltipGroup(child: built ?? const SizedBox.shrink()),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

void main() {
  group('SearchPage', () {
    testWidgets('renders the field and the first page of local results', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(child: SearchPage(autofocus: false, onBack: () {})),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('search-field')), findsOneWidget);
      expect(find.text('Authentication'), findsOneWidget);
      expect(find.byKey(const ValueKey('search-back')), findsOneWidget);
    });

    testWidgets('typing a debounced query filters the local results', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(child: SearchPage(autofocus: false, onBack: () {})),
      );
      await _pumpFrames(tester);
      expect(find.text('Authentication'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'biometric');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'biometric',
      );

      await tester.pump(debounceQueryDuration);
      await _pumpFrames(tester);

      expect(find.text('Biometric unlock'), findsOneWidget);
      expect(find.text('Authentication'), findsNothing);
    });

    testWidgets('onBack fires when the back affordance is tapped', (
      tester,
    ) async {
      var backCalls = 0;
      await tester.pumpWidget(
        _harness(
          child: SearchPage(autofocus: false, onBack: () => backCalls += 1),
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const ValueKey('search-back')));
      await _pumpFrames(tester);
      expect(backCalls, 1);
    });

    testWidgets('renders a corpus fetched through the offline-aware cache seam', (
      tester,
    ) async {
      // A real buildCachedFutureProvider with a local spec — widget tests run
      // under flutter_test's HttpOverrides mock; the socket path is covered by
      // search_corpus_test.dart against a loopback server.
      final cachedCorpusProvider = buildCachedFutureProvider<List<SearchResultViewData>>(
        CachedFutureSpec<List<SearchResultViewData>>(
          key: searchCorpusCacheKey,
          fetch: () async => const <SearchResultViewData>[
            SearchResultViewData(id: 'remote-alpha', title: 'Remote Alpha'),
          ],
          codec: searchCorpusCodec,
          ttlSeconds: searchCorpusTtlSeconds,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchCorpusCachedProvider.overrideWith((ref) => cachedCorpusProvider),
            cacheStoreProvider.overrideWithValue(InMemoryCacheStore()),
            connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
          ],
          child: TranslationProvider(
            child: FTheme(
              data: generated.lightTheme,
              child: MaterialApp(
                theme: generated.lightTheme.toApproximateMaterialTheme(),
                home: SearchPage(autofocus: false, onBack: () {}),
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);
      await _pumpFrames(tester);

      expect(find.text('Remote Alpha'), findsOneWidget);
      expect(find.text('Authentication'), findsNothing);
    });
  });
}
