import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/forms/form_scaffold.dart';

enum FormScaffoldGalleryState {
  disabled(isValid: false, isSubmitting: false),
  enabled(isValid: true, isSubmitting: false),
  submitting(isValid: true, isSubmitting: true);

  const FormScaffoldGalleryState({required this.isValid, required this.isSubmitting});

  final bool isValid;
  final bool isSubmitting;
}

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

class _FormScaffoldPreview extends StatefulWidget {
  const _FormScaffoldPreview({required this.state});

  final FormScaffoldGalleryState state;

  @override
  State<_FormScaffoldPreview> createState() => _FormScaffoldPreviewState();
}

class _FormScaffoldPreviewState extends State<_FormScaffoldPreview> {
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
