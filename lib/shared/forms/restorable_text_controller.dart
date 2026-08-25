import 'package:flutter/material.dart';

mixin RestorableTextControllerBinding<T extends StatefulWidget> on RestorationMixin<T> {
  void registerTextDraft(RestorableString draft, String storageKey) {
    registerForRestoration(draft, storageKey);
  }

  void registerNullableTextDraft(RestorableStringN draft, String storageKey) {
    registerForRestoration(draft, storageKey);
  }

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
