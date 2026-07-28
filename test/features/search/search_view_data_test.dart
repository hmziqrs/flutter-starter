import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/search/search_view_data.dart';

void main() {
  group('SearchResultViewData.matches', () {
    test('empty query matches every item', () {
      const item = SearchResultViewData(
        id: 'a',
        title: 'Authentication',
        subtitle: 'Login flows',
      );
      expect(item.matches(''), isTrue);
      expect(item.matches('   '), isTrue);
    });

    test('case-insensitive substring matches title or subtitle', () {
      const item = SearchResultViewData(
        id: 'a',
        title: 'Authentication',
        subtitle: 'Login flows',
      );
      expect(item.matches('auth'), isTrue);
      expect(item.matches('AUTH'), isTrue);
      expect(item.matches('login'), isTrue);
      expect(item.matches('biometric'), isFalse);
    });

    test('value equality covers id, title, subtitle', () {
      const a = SearchResultViewData(id: 'a', title: 'T', subtitle: 'S');
      const b = SearchResultViewData(id: 'a', title: 'T', subtitle: 'S');
      const c = SearchResultViewData(id: 'a', title: 'T', subtitle: 'X');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('SearchViewData.defaults', () {
    test('ships a backend-free fixture corpus large enough to paginate', () {
      final corpus = SearchViewData.defaults().results;
      expect(corpus, isNotEmpty);
      // Larger than the search page size (8) so pagination is exercised.
      expect(corpus.length, greaterThan(8));
      // Stable ids so the list ValueKeys are deterministic.
      final ids = corpus.map((item) => item.id).toSet();
      expect(ids.length, corpus.length);
    });
  });
}
