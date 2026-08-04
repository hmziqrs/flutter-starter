import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool draggable = true,
  bool barrierDismissible = true,
  bool colored = true,
}) {
  return showFSheet<T>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    draggable: draggable,
    barrierDismissible: barrierDismissible,
    builder: (sheetContext) {
      Widget content = EscapeDismissibleOverlay(child: builder(sheetContext));
      if (colored) {
        content = ColoredBox(
          color: sheetContext.theme.colors.background,
          child: content,
        );
      }
      return content;
    },
  );
}
