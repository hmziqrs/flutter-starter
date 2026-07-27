import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/forms/form_scaffold.dart';

/// Deterministic preview state for the [FormScaffold] gallery cases. One
/// variant per submit affordance; no timers, no async, no persistence (C2: the
/// gallery never fakes a backend action — `onSubmit` is a no-op).
enum FormScaffoldGalleryState {
  /// Submit disabled because the form is not yet valid.
  disabled(isValid: false, isSubmitting: false),

  /// Submit enabled because the form is valid and idle.
  enabled(isValid: true, isSubmitting: false),

  /// Modal busy overlay mounted while the in-flight submit runs.
  submitting(isValid: true, isSubmitting: true);

  const FormScaffoldGalleryState({required this.isValid, required this.isSubmitting});

  /// Whether the preview form is considered valid (gates the submit button).
  final bool isValid;

  /// Whether the modal busy overlay is mounted over the preview form.
  final bool isSubmitting;
}

/// Builds the [FormScaffold] gallery cases: submit disabled, submit enabled,
/// and a submitting form with the busy overlay mounted. Every case is a static
/// fixture pinned to its [FormScaffoldGalleryState] — `onSubmit` is a no-op so
/// the gallery never claims a backend action succeeded.
List<GalleryCase> buildFormScaffoldingGalleryCases() {
  return [
    for (final state in FormScaffoldGalleryState.values)
      TypedGalleryCase<FormScaffoldGalleryState>(
        id: 'formScaffold.${state.name}',
        screenId: 'form-scaffold',
        screenLabelBuilder: (translations) => translations.devGallery.screenFormScaffolding,
        caseLabelBuilder: (translations) => switch (state) {
          FormScaffoldGalleryState.disabled => translations.devGallery.caseFormScaffoldDisabled,
          FormScaffoldGalleryState.enabled => translations.devGallery.caseFormScaffoldEnabled,
          FormScaffoldGalleryState.submitting => translations.devGallery.caseFormScaffoldSubmitting,
        },
        stateFactory: (_) => state,
        pageFactory: (context, state) => _FormScaffoldPreview(state: state),
      ),
  ];
}

/// Mounts a [FormScaffold] with a single sample field pinned to the preview
/// state. The submit callback is a no-op Future so the gallery exercises the
/// chrome (button enabled/disabled, busy overlay) without faking success.
class _FormScaffoldPreview extends StatefulWidget {
  const _FormScaffoldPreview({required this.state});

  final FormScaffoldGalleryState state;

  @override
  State<_FormScaffoldPreview> createState() => _FormScaffoldPreviewState();
}

class _FormScaffoldPreviewState extends State<_FormScaffoldPreview> {
  // The gallery preview is fully static; the form key is read-only and the
  // FormState is disposed by the framework when the Form unmounts.
  final _formKey = GlobalKey<FormState>(debugLabel: 'form-scaffold-preview');

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: FormScaffold(
        formKey: _formKey,
        isValid: widget.state.isValid,
        isSubmitting: widget.state.isSubmitting,
        onSubmit: () async {},
        submitLabel: translations.common.save,
        heading: Text(
          translations.devGallery.preview,
          style: context.theme.typography.display.xl2,
        ),
        subheading: Text(
          translations.common.notConnected,
          style: context.theme.typography.body.md,
        ),
        fields: FTextFormField(
          label: Text(translations.auth.common.email),
          enabled: !widget.state.isSubmitting,
        ),
      ),
    );
  }
}
