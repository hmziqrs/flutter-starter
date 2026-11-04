import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/widgets/lists/equal_height_row.dart';

void main() {
  Widget harness({required TextDirection direction}) {
    return Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 300,
          child: EqualHeightRow(
            children: [
              Expanded(
                flex: 2,
                // A LayoutBuilder is what makes IntrinsicHeight throw.
                child: LayoutBuilder(
                  builder: (context, constraints) => const SizedBox(
                    key: ValueKey('short'),
                    height: 40,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(child: SizedBox(key: ValueKey('tall'), height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('accepts a LayoutBuilder child and gives every child the tallest height', (
    tester,
  ) async {
    await tester.pumpWidget(harness(direction: TextDirection.ltr));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(EqualHeightRow)), const Size(300, 100));
    expect(tester.getSize(find.byType(LayoutBuilder)), const Size(280 * 2 / 3, 100));
    expect(tester.getSize(find.byKey(const ValueKey('tall'))).height, 100);
  });

  testWidgets('shares the width by flex and keeps fixed children such as gaps', (tester) async {
    await tester.pumpWidget(harness(direction: TextDirection.ltr));

    expect(tester.getTopLeft(find.byType(LayoutBuilder)).dx, 0);
    expect(tester.getTopRight(find.byKey(const ValueKey('tall'))).dx, 300);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('tall'))).dx,
      closeTo(280 * 2 / 3 + 20, 0.01),
    );
  });

  testWidgets('lays children out from the end in right-to-left text', (tester) async {
    await tester.pumpWidget(harness(direction: TextDirection.rtl));

    expect(tester.getTopRight(find.byType(LayoutBuilder)).dx, 300);
    expect(tester.getTopLeft(find.byKey(const ValueKey('tall'))).dx, closeTo(0, 0.01));
  });
}
