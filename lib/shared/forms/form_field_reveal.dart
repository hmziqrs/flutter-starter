import 'package:flutter/widgets.dart';

typedef InvalidFieldTarget = ({
  FormFieldState<Object?>? field,
  BuildContext? context,
  FocusNode focusNode,
});

Future<void> revealFirstInvalid(
  Set<FormFieldState<Object?>> invalidFields, {
  required Iterable<InvalidFieldTarget> orderedTargets,
  required bool Function() isMounted,
}) async {
  for (final target in orderedTargets) {
    final field = target.field;
    final fieldContext = target.context;
    if (field == null || fieldContext == null || !invalidFields.contains(field)) {
      continue;
    }
    await Scrollable.ensureVisible(fieldContext, alignment: 0.2);
    if (isMounted()) target.focusNode.requestFocus();
    return;
  }
}
