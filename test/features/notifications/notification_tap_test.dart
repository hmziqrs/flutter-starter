import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/notifications/notification_tap.dart';

void main() {
  group('NotificationMessage', () {
    test('value equality across title, body, data', () {
      const a = NotificationMessage(title: 't', body: 'b', data: {'k': 'v'});
      const b = NotificationMessage(title: 't', body: 'b', data: {'k': 'v'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on title / body / data', () {
      const base = NotificationMessage(title: 't', body: 'b', data: {'k': 'v'});
      expect(base != const NotificationMessage(title: 't2', body: 'b', data: {'k': 'v'}), true);
      expect(base != const NotificationMessage(title: 't', body: 'b2', data: {'k': 'v'}), true);
      expect(base != const NotificationMessage(title: 't', body: 'b', data: {'k': 'v2'}), true);
      expect(base != const NotificationMessage(title: 't', body: 'b', data: {'k2': 'v'}), true);
    });

    test('data defaults to empty immutable map', () {
      const msg = NotificationMessage(title: 't');
      expect(msg.data, isEmpty);
    });

    test('copyWith merges fields without mutating the source', () {
      const source = NotificationMessage(title: 't', body: 'b', data: {'k': 'v'});
      final updated = source.copyWith(title: 't2', data: {'k2': 'v2'});
      expect(updated.title, 't2');
      expect(updated.body, 'b');
      expect(updated.data, {'k2': 'v2'});
      expect(source.title, 't');
      expect(source.data, {'k': 'v'});
    });
  });

  group('NotificationTap', () {
    test('value equality across targetRoute + params', () {
      const a = NotificationTap(targetRoute: 'home', params: {'a': '1'});
      const b = NotificationTap(targetRoute: 'home', params: {'a': '1'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on targetRoute + params', () {
      const base = NotificationTap(targetRoute: 'home', params: {'a': '1'});
      expect(base != const NotificationTap(targetRoute: 'settings', params: {'a': '1'}), true);
      expect(base != const NotificationTap(targetRoute: 'home', params: {'a': '2'}), true);
      expect(base != const NotificationTap(targetRoute: 'home', params: {'b': '1'}), true);
    });

    test('params defaults to empty immutable map', () {
      const tap = NotificationTap(targetRoute: 'home');
      expect(tap.params, isEmpty);
    });
  });
}
