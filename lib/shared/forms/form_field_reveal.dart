import 'package:flutter/widgets.dart';

/// A form field's state, location, and focus target in explicit visual order.
///
/// Callers build an ordered iterable of these (one per field, top-to-bottom as
/// the user sees them) so [revealFirstInvalid] can scroll to and focus the
/// earliest field that failed validation. The `field` and `context` members are
/// nullable because they are read live from a `GlobalKey` whose state/context
/// may not be mounted yet; the reveal skips any target missing either.
typedef InvalidFieldTarget = ({
  FormFieldState<Object?>? field,
  BuildContext? context,
  FocusNode focusNode,
});

/// Reveals and focuses the first invalid field in explicit visual order.
///
/// Walks [orderedTargets] in order and, for the first entry whose `field` is in
/// [invalidFields], scrolls it into view via [Scrollable.ensureVisible] and then
/// requests focus on its [FocusNode]. This uses `ensureVisible` rather than an
/// animation, so the reveal is deterministic and reduce-motion-safe, and
/// navigation never gates on it (audit checklist #5). [isMounted] is consulted
/// before requesting focus so a submit that unmounts the form mid-flight cannot
/// touch a disposed node.
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
