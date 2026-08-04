import 'package:flutter/material.dart';

/// Binds a [TextEditingController]'s text to a [RestorableString] (or
/// [RestorableStringN]) for state restoration on auth-style forms.
///
/// Mix this onto a [State] that also mixes in [RestorationMixin]:
///
/// ```dart
/// class _MyViewState extends ConsumerState<MyPage>
///     with RestorationMixin<MyPage>, RestorableTextControllerBinding<MyPage> {
///   final RestorableString _emailDraft = RestorableString('');
///   late final TextEditingController _emailController;
///   // Created in initState; stored so dispose can remove the listener.
///   late final VoidCallback _syncEmailDraft;
///
///   @override
///   String get restorationId => 'my-view';
///
///   @override
///   void initState() {
///     super.initState();
///     // Assign the controller BEFORE reading it inside the syncer closure.
///     // A cascade (`..addListener(textDraftSyncer(.., _emailController))`)
///     // evaluates the argument before the assignment lands and throws
///     // LateInitializationError.
///     _emailController = TextEditingController();
///     _syncEmailDraft = textDraftSyncer(_emailDraft, _emailController);
///     _emailController.addListener(_syncEmailDraft);
///   }
///
///   @override
///   void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
///     // Registers the draft, then the caller writes the restored value back
///     // using whatever strategy fits (plain .text=, a TextEditingValue with
///     // selection, a looped / gated variant, ...).
///     registerTextDraft(_emailDraft, 'email_draft');
///     if (_emailController.text != _emailDraft.value) {
///       _emailController.text = _emailDraft.value;
///     }
///   }
///
///   @override
///   void dispose() {
///     _emailController
///       ..removeListener(_syncEmailDraft)
///       ..dispose();
///     _emailDraft.dispose(); // owned by the caller
///     super.dispose();
///   }
/// }
/// ```
///
/// The write-back strategy is intentionally left to the caller so the OTP
/// field's [TextEditingValue]-with-selection and any looped / gated variants
/// still fit. This mixin centralizes register + sync only; disposing the
/// restorable remains the caller's responsibility since it owns the field.
mixin RestorableTextControllerBinding<T extends StatefulWidget> on RestorationMixin<T> {
  /// Registers [draft] for restoration under [storageKey]. Call from
  /// [RestorationMixin.restoreState]; the caller then reads [RestorableString.value]
  /// and applies it to its controller.
  void registerTextDraft(RestorableString draft, String storageKey) {
    registerForRestoration(draft, storageKey);
  }

  /// [RestorableStringN] variant of [registerTextDraft].
  void registerNullableTextDraft(RestorableStringN draft, String storageKey) {
    registerForRestoration(draft, storageKey);
  }

  /// Creates a listener that mirrors [controller]'s text into [draft] without
  /// feedback loops. Add the returned closure via `controller.addListener(...)`
  /// (typically in [State.initState]) and remove it in [State.dispose].
  VoidCallback textDraftSyncer(
    RestorableString draft,
    TextEditingController controller,
  ) {
    return () {
      if (controller.text != draft.value) {
        draft.value = controller.text;
      }
    };
  }

  /// [RestorableStringN] variant of [textDraftSyncer].
  VoidCallback nullableTextDraftSyncer(
    RestorableStringN draft,
    TextEditingController controller,
  ) {
    return () {
      if (controller.text != draft.value) {
        draft.value = controller.text;
      }
    };
  }
}
