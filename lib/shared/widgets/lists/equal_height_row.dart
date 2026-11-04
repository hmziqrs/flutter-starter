import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A row whose children all take the height of the tallest one, with the same
/// child API as [Row]: [Expanded] children share the width left by the fixed
/// ones, such as gaps.
///
/// Use it instead of `IntrinsicHeight(child: Row(...))` whenever a child might
/// contain a [LayoutBuilder]. Intrinsic sizing cannot run a layout callback, so
/// that combination throws at runtime, and only on the wide layouts that use
/// the row. This measures each child by really laying it out, then lays it out
/// again at the shared height.
class EqualHeightRow extends MultiChildRenderObjectWidget {
  const EqualHeightRow({required super.children, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderEqualHeightRow(textDirection: Directionality.of(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderEqualHeightRow).textDirection = Directionality.of(context);
  }
}

final class _RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlexParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData> {
  _RenderEqualHeightRow({required this._textDirection});

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexParentData) {
      child.parentData = FlexParentData();
    }
  }

  // Reporting no intrinsic size is deliberate: answering would mean running
  // the children's layout callbacks speculatively, which is the crash this
  // widget exists to avoid.
  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(Size.zero);

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    assert(width.isFinite, 'EqualHeightRow needs a bounded width.');

    final widths = <RenderBox, double>{};
    var fixedWidth = 0.0;
    var totalFlex = 0;
    var tallest = 0.0;

    for (var child = firstChild; child != null; child = childAfter(child)) {
      final flex = (child.parentData! as FlexParentData).flex ?? 0;
      if (flex > 0) {
        totalFlex += flex;
      } else {
        child.layout(const BoxConstraints(), parentUsesSize: true);
        widths[child] = child.size.width;
        fixedWidth += child.size.width;
        tallest = math.max(tallest, child.size.height);
      }
    }

    final widthPerFlex = totalFlex == 0 ? 0.0 : math.max(0, width - fixedWidth) / totalFlex;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final flex = (child.parentData! as FlexParentData).flex ?? 0;
      if (flex <= 0) continue;
      final childWidth = widthPerFlex * flex;
      child.layout(BoxConstraints.tightFor(width: childWidth), parentUsesSize: true);
      widths[child] = childWidth;
      tallest = math.max(tallest, child.size.height);
    }

    final height = constraints.constrainHeight(tallest);
    var x = _textDirection == TextDirection.ltr ? 0.0 : width;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final childWidth = widths[child]!;
      child.layout(
        BoxConstraints.tightFor(width: childWidth, height: height),
        parentUsesSize: true,
      );
      final parentData = child.parentData! as FlexParentData;
      if (_textDirection == TextDirection.ltr) {
        parentData.offset = Offset(x, 0);
        x += childWidth;
      } else {
        x -= childWidth;
        parentData.offset = Offset(x, 0);
      }
    }
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
