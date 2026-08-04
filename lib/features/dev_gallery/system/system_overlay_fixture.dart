import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_bottom_sheet.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

part 'system_overlay_fixture.freezed.dart';

enum SystemOverlayFixtureKind {
  dialog,
  sheet,
  toast,
  popover,
  tooltip,
  keyboardInset,
}

@freezed
abstract class SystemOverlayFixtureState with _$SystemOverlayFixtureState {
  const factory SystemOverlayFixtureState({required SystemOverlayFixtureKind kind}) =
      _SystemOverlayFixtureState;
}

class SystemOverlayFixturePage extends StatelessWidget {
  const SystemOverlayFixturePage({required this.state, super.key});

  final SystemOverlayFixtureState state;

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      child: SafeArea(
        child: switch (state.kind) {
          SystemOverlayFixtureKind.dialog => _OverlayTrigger(
            label: context.t.devGallery.caseDialog,
            triggerKey: const ValueKey('overlay-dialog-trigger'),
            onPress: () => _showDialog(context),
          ),
          SystemOverlayFixtureKind.sheet => _OverlayTrigger(
            label: context.t.devGallery.caseSheet,
            triggerKey: const ValueKey('overlay-sheet-trigger'),
            onPress: () => _showSheet(context),
          ),
          SystemOverlayFixtureKind.toast => _OverlayTrigger(
            label: context.t.devGallery.caseToast,
            triggerKey: const ValueKey('overlay-toast-trigger'),
            onPress: () => _showToast(context),
          ),
          SystemOverlayFixtureKind.popover => _PopoverFixture(
            label: context.t.devGallery.casePopover,
          ),
          SystemOverlayFixtureKind.tooltip => _TooltipFixture(
            label: context.t.devGallery.caseTooltip,
          ),
          SystemOverlayFixtureKind.keyboardInset => const _KeyboardInsetFixture(),
        },
      ),
    );
  }

  void _showDialog(BuildContext context) {
    final translations = context.t;
    unawaited(
      showFDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context, _, animation) => EscapeDismissibleOverlay(
          child: FDialog(
            key: const ValueKey('overlay-dialog-content'),
            animation: animation,
            semanticsLabel: translations.devGallery.caseDialog,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translations.devGallery.caseDialog,
                    style: context.theme.typography.display.lg,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(translations.common.notConnected),
                  const SizedBox(height: AppSpacing.xl),
                  FButton(
                    key: const ValueKey('overlay-dialog-close'),
                    onPress: () => Navigator.of(context).pop(),
                    child: Text(translations.common.close),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final translations = context.t;
    unawaited(
      showAppBottomSheet<void>(
        context: context,
        barrierDismissible: false,
        draggable: false,
        colored: false,
        builder: (context) => Semantics(
          label: translations.devGallery.caseSheet,
          container: true,
          child: Padding(
            key: const ValueKey('overlay-sheet-content'),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  translations.devGallery.caseSheet,
                  style: context.theme.typography.display.lg,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(translations.common.notConnected),
                const SizedBox(height: AppSpacing.xl),
                FButton(
                  key: const ValueKey('overlay-sheet-close'),
                  onPress: () => Navigator.of(context).pop(),
                  child: Text(translations.common.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context) {
    final translations = context.t;
    showFToast(
      context: context,
      title: Text(translations.devGallery.caseToast),
      description: Text(translations.common.notConnected),
      duration: null,
      suffixBuilder: (context, entry) => FButton(
        key: const ValueKey('overlay-toast-close'),
        variant: FButtonVariant.ghost,
        onPress: entry.dismiss,
        child: Text(translations.common.close),
      ),
    );
  }
}

class _OverlayTrigger extends StatelessWidget {
  const _OverlayTrigger({
    required this.label,
    required this.triggerKey,
    required this.onPress,
  });

  final String label;
  final Key triggerKey;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: FButton(
            key: triggerKey,
            onPress: onPress,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _PopoverFixture extends StatelessWidget {
  const _PopoverFixture({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Center(
      child: FPopover(
        semanticsLabel: label,
        control: const FPopoverControl.managed(initial: false),
        popoverBuilder: (context, controller) => Padding(
          key: const ValueKey('overlay-popover-content'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(translations.common.notConnected),
              const SizedBox(height: AppSpacing.md),
              FButton(
                key: const ValueKey('overlay-popover-close'),
                variant: FButtonVariant.ghost,
                onPress: () => unawaited(controller.hide(animated: false)),
                child: Text(translations.common.close),
              ),
            ],
          ),
        ),
        builder: (context, controller, _) => FButton(
          key: const ValueKey('overlay-popover-trigger'),
          onPress: () => unawaited(controller.toggle(animated: false)),
          child: Text(label),
        ),
      ),
    );
  }
}

class _TooltipFixture extends StatelessWidget {
  const _TooltipFixture({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final feedback = context.t.common.notConnected;
    return Center(
      child: FTooltip(
        control: const FTooltipControl.managed(initial: false),
        hover: false,
        longPress: false,
        semanticsLabel: feedback,
        tipBuilder: (context, _) => Text(
          feedback,
          key: const ValueKey('overlay-tooltip-content'),
        ),
        builder: (context, controller, _) => FButton(
          key: const ValueKey('overlay-tooltip-trigger'),
          onPress: () => unawaited(controller.toggle(animated: false)),
          child: Text(label),
        ),
      ),
    );
  }
}

class _KeyboardInsetFixture extends StatefulWidget {
  const _KeyboardInsetFixture();

  @override
  State<_KeyboardInsetFixture> createState() => _KeyboardInsetFixtureState();
}

class _KeyboardInsetFixtureState extends State<_KeyboardInsetFixture> {
  var _submitted = false;

  void _submit() => setState(() => _submitted = true);

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Form(
      key: const ValueKey('overlay-keyboard-form'),
      child: ListView(
        key: const ValueKey('overlay-keyboard-scroll'),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        children: [
          FTextFormField(
            key: const ValueKey('overlay-keyboard-field'),
            label: Text(translations.devGallery.keyboardInsets),
            textInputAction: TextInputAction.done,
            onSubmit: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          FButton(
            key: const ValueKey('overlay-keyboard-submit'),
            onPress: _submit,
            child: Text(translations.common.done),
          ),
          if (_submitted) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              translations.common.notConnected,
              key: const ValueKey('overlay-keyboard-feedback'),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
