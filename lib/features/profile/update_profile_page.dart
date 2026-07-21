import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

typedef ProfileSaveCallback = FutureOr<void> Function(ProfileDraft draft);

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({
    required this.initialDraft,
    required this.onSave,
    required this.onAvatarFeedback,
    this.presentationState = const ProfilePresentationState.defaults(),
    super.key,
  });

  final ProfileDraft initialDraft;
  final ProfilePresentationState presentationState;
  final ProfileSaveCallback onSave;
  final VoidCallback onAvatarFeedback;

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  static const displayNameMaximum = 80;
  static const bioMaximum = 160;

  final _formKey = GlobalKey<FormState>();
  final _displayNameFieldKey = GlobalKey<FormFieldState<String>>();
  final _usernameFieldKey = GlobalKey<FormFieldState<String>>();
  final _bioFieldKey = GlobalKey<FormFieldState<String>>();
  final _displayNameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _bioFocusNode = FocusNode();
  final _scrollController = ScrollController();

  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late ProfileDraft _baselineDraft;
  late ProfilePresentationPhase _phase;
  bool _discarding = false;
  bool _dialogVisible = false;
  bool _synchronizing = false;
  String _savedDisplayName = '';
  String _savedUsername = '';
  String _savedBio = '';

  ProfileDraft get _currentDraft {
    return ProfileDraft(
      displayName: _displayNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      bio: _bioController.text,
    );
  }

  bool get _isDirty => _currentDraft != _baselineDraft;

  bool get _isSaving => _phase == ProfilePresentationPhase.saving;

  @override
  void initState() {
    super.initState();
    _baselineDraft = widget.initialDraft;
    final draft = widget.presentationState.draft ?? widget.initialDraft;
    _phase = widget.presentationState.phase;
    _displayNameController = TextEditingController(text: draft.displayName)
      ..addListener(_onChanged);
    _usernameController = TextEditingController(text: draft.username)..addListener(_onChanged);
    _emailController = TextEditingController(text: draft.email);
    _bioController = TextEditingController(text: draft.bio)..addListener(_onChanged);

    if (_phase case ProfilePresentationPhase.invalid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateInjectedState());
    } else if (_phase case ProfilePresentationPhase.discardPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDiscardDialog());
    }
  }

  @override
  void didUpdateWidget(covariant UpdateProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDraft == widget.initialDraft &&
        oldWidget.presentationState == widget.presentationState) {
      return;
    }

    _baselineDraft = widget.initialDraft;
    final draft = widget.presentationState.draft ?? widget.initialDraft;
    _synchronizing = true;
    _phase = widget.presentationState.phase;
    _replaceControllerText(_displayNameController, draft.displayName);
    _replaceControllerText(_usernameController, draft.username);
    _replaceControllerText(_emailController, draft.email);
    _replaceControllerText(_bioController, draft.bio);
    _synchronizing = false;

    if (_phase case ProfilePresentationPhase.invalid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateInjectedState());
    } else if (_phase case ProfilePresentationPhase.discardPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDiscardDialog());
    }
  }

  @override
  void dispose() {
    _displayNameController
      ..removeListener(_onChanged)
      ..dispose();
    _usernameController
      ..removeListener(_onChanged)
      ..dispose();
    _emailController.dispose();
    _bioController
      ..removeListener(_onChanged)
      ..dispose();
    _displayNameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _bioFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, layoutClass) {
        final form = _ProfileForm(
          formKey: _formKey,
          displayNameFieldKey: _displayNameFieldKey,
          usernameFieldKey: _usernameFieldKey,
          bioFieldKey: _bioFieldKey,
          displayNameController: _displayNameController,
          usernameController: _usernameController,
          emailController: _emailController,
          bioController: _bioController,
          displayNameFocusNode: _displayNameFocusNode,
          usernameFocusNode: _usernameFocusNode,
          bioFocusNode: _bioFocusNode,
          phase: _phase,
          onAvatarFeedback: widget.onAvatarFeedback,
          onDisplayNameSaved: (value) => _savedDisplayName = value ?? '',
          onUsernameSaved: (value) => _savedUsername = value ?? '',
          onBioSaved: (value) => _savedBio = value ?? '',
          onSave: _submit,
        );

        return PopScope<void>(
          canPop: !_isDirty || _discarding,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _isDirty) {
              unawaited(_showDiscardDialog());
            }
          },
          child: ListView(
            key: ValueKey('profile-layout-${layoutClass.name}'),
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xl,
              AppSpacing.xl2,
              AppSpacing.xl,
              AppSpacing.xl3 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              if (_isDirty) const SizedBox.shrink(key: ValueKey('profile-dirty-indicator')),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: layoutClass == AppLayoutClass.expanded
                        ? AppSizes.wideContentMaxWidth
                        : AppSizes.formContentMaxWidth,
                  ),
                  child: switch (layoutClass) {
                    AppLayoutClass.compact || AppLayoutClass.medium => form,
                    AppLayoutClass.expanded => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: form),
                        const SizedBox(width: AppSpacing.xl2),
                        SizedBox(
                          width: 320,
                          child: _ProfilePreview(draft: _currentDraft),
                        ),
                      ],
                    ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onChanged() {
    if (!mounted || _isSaving || _synchronizing) return;
    final nextPhase = _isDirty ? ProfilePresentationPhase.dirty : ProfilePresentationPhase.idle;
    if (_phase != nextPhase) {
      setState(() => _phase = nextPhase);
    } else {
      setState(() {});
    }
  }

  Future<void> _validateInjectedState() async {
    if (!mounted) return;
    final invalidFields = _formKey.currentState?.validateGranularly() ?? const {};
    if (invalidFields.isNotEmpty) {
      await _revealFirstInvalid(invalidFields);
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final form = _formKey.currentState;
    if (form == null) return;

    final invalidFields = form.validateGranularly();
    if (invalidFields.isNotEmpty) {
      setState(() => _phase = ProfilePresentationPhase.invalid);
      await _revealFirstInvalid(invalidFields);
      return;
    }

    form.save();
    final draft = ProfileDraft(
      displayName: _savedDisplayName.trim(),
      username: _savedUsername.trim().toLowerCase(),
      email: _emailController.text.trim(),
      bio: _savedBio.trim(),
    );

    setState(() => _phase = ProfilePresentationPhase.saving);
    try {
      await Future<void>.sync(() => widget.onSave(draft));
    } on Object {
      if (mounted) {
        setState(() => _phase = ProfilePresentationPhase.dirty);
      }
      rethrow;
    }
    if (!mounted) return;

    _replaceControllerText(_displayNameController, draft.displayName);
    _replaceControllerText(_usernameController, draft.username);
    _replaceControllerText(_bioController, draft.bio);
    _baselineDraft = draft;
    setState(() => _phase = ProfilePresentationPhase.saved);
  }

  Future<void> _revealFirstInvalid(Set<FormFieldState<Object?>> invalidFields) async {
    final orderedFields = [
      (_displayNameFieldKey, _displayNameFocusNode),
      (_usernameFieldKey, _usernameFocusNode),
      (_bioFieldKey, _bioFocusNode),
    ];
    for (final (key, focusNode) in orderedFields) {
      final state = key.currentState;
      if (state != null && invalidFields.contains(state)) {
        await Scrollable.ensureVisible(
          state.context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 1),
        );
        if (mounted) focusNode.requestFocus();
        return;
      }
    }
  }

  Future<void> _showDiscardDialog() async {
    if (!mounted || _dialogVisible) return;
    _dialogVisible = true;
    if (_phase != ProfilePresentationPhase.discardPrompt) {
      setState(() => _phase = ProfilePresentationPhase.discardPrompt);
    }

    final shouldDiscard = await showFDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, style, animation) {
        final translations = dialogContext.t.profile.update;
        return EscapeDismissibleOverlay(
          child: FDialog(
            key: const ValueKey('profile-discard-dialog'),
            animation: animation,
            semanticsLabel: translations.discardTitle,
            builder: (_, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(translations.discardTitle, style: style.titleTextStyle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(translations.discardBody, style: style.bodyTextStyle),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FButton(
                        key: const ValueKey('profile-keep-editing'),
                        variant: .outline,
                        mainAxisSize: .min,
                        builder: (_, _, _, _, _, child) => Flexible(child: child!),
                        onPress: () => Navigator.of(dialogContext).pop(false),
                        child: Text(translations.stay),
                      ),
                      FButton(
                        key: const ValueKey('profile-discard-changes'),
                        variant: .destructive,
                        mainAxisSize: .min,
                        builder: (_, _, _, _, _, child) => Flexible(child: child!),
                        onPress: () => Navigator.of(dialogContext).pop(true),
                        child: Text(translations.discard),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    _dialogVisible = false;
    if (!mounted) return;

    if (shouldDiscard ?? false) {
      _discarding = true;
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _phase = _isDirty ? ProfilePresentationPhase.dirty : ProfilePresentationPhase.idle;
    });
  }

  void _replaceControllerText(TextEditingController controller, String text) {
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.displayNameFieldKey,
    required this.usernameFieldKey,
    required this.bioFieldKey,
    required this.displayNameController,
    required this.usernameController,
    required this.emailController,
    required this.bioController,
    required this.displayNameFocusNode,
    required this.usernameFocusNode,
    required this.bioFocusNode,
    required this.phase,
    required this.onAvatarFeedback,
    required this.onDisplayNameSaved,
    required this.onUsernameSaved,
    required this.onBioSaved,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final GlobalKey<FormFieldState<String>> displayNameFieldKey;
  final GlobalKey<FormFieldState<String>> usernameFieldKey;
  final GlobalKey<FormFieldState<String>> bioFieldKey;
  final TextEditingController displayNameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController bioController;
  final FocusNode displayNameFocusNode;
  final FocusNode usernameFocusNode;
  final FocusNode bioFocusNode;
  final ProfilePresentationPhase phase;
  final VoidCallback onAvatarFeedback;
  final ValueChanged<String?> onDisplayNameSaved;
  final ValueChanged<String?> onUsernameSaved;
  final ValueChanged<String?> onBioSaved;
  final VoidCallback onSave;

  bool get _enabled => phase != ProfilePresentationPhase.saving;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final profile = translations.profile.update;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(profile.title, style: context.theme.typography.display.xl3),
          const SizedBox(height: AppSpacing.sm),
          Text(profile.body, style: context.theme.typography.body.lg),
          const SizedBox(height: AppSpacing.xl2),
          _AvatarEditor(onAvatarFeedback: onAvatarFeedback, enabled: _enabled),
          const SizedBox(height: AppSpacing.xl2),
          FTextFormField(
            key: const ValueKey('profile-display-name'),
            formFieldKey: displayNameFieldKey,
            control: .managed(controller: displayNameController),
            focusNode: displayNameFocusNode,
            label: Text(profile.displayName),
            enabled: _enabled,
            textCapitalization: .words,
            textInputAction: .next,
            autofillHints: const [AutofillHints.name],
            maxLength: _UpdateProfilePageState.displayNameMaximum,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            autovalidateMode: .onUserInteractionIfError,
            validator: (value) => _required(value, profile.displayName, translations),
            onSaved: onDisplayNameSaved,
            onSubmit: (_) => usernameFocusNode.requestFocus(),
          ),
          const SizedBox(height: AppSpacing.lg),
          FTextFormField(
            key: const ValueKey('profile-username'),
            formFieldKey: usernameFieldKey,
            control: .managed(controller: usernameController),
            focusNode: usernameFocusNode,
            label: Text(profile.username),
            enabled: _enabled,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: .next,
            maxLength: 24,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            autovalidateMode: .onUserInteractionIfError,
            validator: (value) => _username(value, translations),
            onSaved: onUsernameSaved,
            onSubmit: (_) => bioFocusNode.requestFocus(),
          ),
          const SizedBox(height: AppSpacing.lg),
          FTextFormField.email(
            key: const ValueKey('profile-email'),
            control: .managed(controller: emailController),
            label: Text(profile.email),
            description: Text(profile.emailReadOnly),
            readOnly: true,
            canRequestFocus: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          FTextFormField(
            key: const ValueKey('profile-bio'),
            formFieldKey: bioFieldKey,
            control: .managed(controller: bioController),
            focusNode: bioFocusNode,
            label: Text(profile.bio),
            enabled: _enabled,
            keyboardType: TextInputType.multiline,
            textCapitalization: .sentences,
            textInputAction: .newline,
            minLines: 4,
            maxLines: 6,
            maxLength: _UpdateProfilePageState.bioMaximum,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            counterBuilder: (context, currentLength, maximum, _) {
              return Text(
                profile.bioCounter(
                  count: currentLength,
                  maximum: maximum ?? _UpdateProfilePageState.bioMaximum,
                ),
              );
            },
            autovalidateMode: .onUserInteractionIfError,
            validator: (value) => _bio(value, translations),
            onSaved: onBioSaved,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (phase == ProfilePresentationPhase.saved) ...[
            FAlert(
              key: const ValueKey('profile-saved'),
              icon: const Icon(FLucideIcons.circleCheck),
              title: Text(profile.saved),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          FButton(
            key: const ValueKey('profile-save'),
            onPress: _enabled ? onSave : null,
            prefix: phase == ProfilePresentationPhase.saving
                ? FCircularProgress(semanticsLabel: profile.saving)
                : const Icon(FLucideIcons.save),
            child: Text(
              phase == ProfilePresentationPhase.saving ? profile.saving : profile.save,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.onAvatarFeedback, required this.enabled});

  final VoidCallback onAvatarFeedback;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.profile.update;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            Semantics(
              image: true,
              label: translations.avatar,
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.theme.colors.muted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(FLucideIcons.userRound, size: 32),
              ),
            ),
            FButton(
              key: const ValueKey('profile-avatar-feedback'),
              variant: .outline,
              mainAxisSize: .min,
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              onPress: enabled ? onAvatarFeedback : null,
              child: Text(translations.changeAvatar),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.profile.update;
    return FCard(
      key: const ValueKey('profile-preview'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              image: true,
              label: translations.avatar,
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.theme.colors.muted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(FLucideIcons.userRound, size: 36),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              draft.displayName,
              key: const ValueKey('profile-preview-name'),
              style: context.theme.typography.display.lg,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('@${draft.username}', style: context.theme.typography.body.sm),
            if (draft.bio.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(draft.bio, style: context.theme.typography.body.sm),
            ],
          ],
        ),
      ),
    );
  }
}

String? _required(String? value, String field, Translations translations) {
  if (value == null || value.trim().isEmpty) {
    return translations.validation.required(field: field);
  }
  return null;
}

String? _username(String? value, Translations translations) {
  final normalized = value?.trim() ?? '';
  if (!RegExp(r'^[A-Za-z0-9._]{3,24}$').hasMatch(normalized)) {
    return translations.validation.username;
  }
  return null;
}

String? _bio(String? value, Translations translations) {
  if ((value ?? '').characters.length > _UpdateProfilePageState.bioMaximum) {
    return translations.validation.bioTooLong(maximum: _UpdateProfilePageState.bioMaximum);
  }
  return null;
}
