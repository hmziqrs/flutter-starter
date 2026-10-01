import 'package:flutter_test/flutter_test.dart';

/// Pumps eight bounded 100ms frames so pending frames and short animations
/// resolve; the bounded alternative to pumpAndSettle mandated for widget tests.
Future<void> pumpAppFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
