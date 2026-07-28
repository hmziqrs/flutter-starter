import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/media/noop_media_picker.dart';

void main() {
  group('NoopMediaPicker', () {
    const picker = NoopMediaPicker();

    test('pickImage from library returns null honestly (never fakes an image)', () async {
      final result = await picker.pickImage();
      expect(result, isNull);
    });

    test('pickImage from camera returns null honestly (never fakes an image)', () async {
      final result = await picker.pickImage(fromCamera: true);
      expect(result, isNull);
    });

    test('is a const-constructible honest default (no backend wiring)', () async {
      const a = NoopMediaPicker();
      const b = NoopMediaPicker();
      expect(await a.pickImage(), await b.pickImage());
    });
  });

  group('PickedMedia value object', () {
    const media = PickedMedia(path: '/tmp/a.jpg', mimeType: 'image/jpeg', fromCamera: false);

    test('equal when all fields match', () {
      const other = PickedMedia(path: '/tmp/a.jpg', mimeType: 'image/jpeg', fromCamera: false);
      expect(media, other);
      expect(media.hashCode, other.hashCode);
    });

    test('not equal when path differs', () {
      const other = PickedMedia(path: '/tmp/b.jpg', mimeType: 'image/jpeg', fromCamera: false);
      expect(media == other, isFalse);
    });

    test('not equal when mimeType differs', () {
      const other = PickedMedia(path: '/tmp/a.jpg', mimeType: 'image/png', fromCamera: false);
      expect(media == other, isFalse);
    });

    test('not equal when fromCamera differs', () {
      const other = PickedMedia(path: '/tmp/a.jpg', mimeType: 'image/jpeg', fromCamera: true);
      expect(media == other, isFalse);
    });

    test('tolerates an empty mimeType without crashing', () {
      const empty = PickedMedia(path: '/tmp/a', mimeType: '', fromCamera: false);
      expect(empty.mimeType, '');
      expect(empty == media, isFalse);
    });
  });
}
