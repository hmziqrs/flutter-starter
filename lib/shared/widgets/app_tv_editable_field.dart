import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';

typedef AppTvEditableFieldBuilder =
    Widget Function(
      BuildContext context,
      FocusNode editorFocusNode,
      AppTvEditingComplete completeEditing,
    );

typedef AppTvEditingComplete = void Function({FocusNode? nextFocusNode});

class AppTvEditableField extends StatefulWidget {
  const AppTvEditableField({
    required this.activationKey,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.builder,
    this.enabled = true,
    this.secure = false,
    this.autofocus = false,
    super.key,
  });

  final Key activationKey;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final AppTvEditableFieldBuilder builder;
  final bool enabled;
  final bool secure;
  final bool autofocus;

  static bool get editorHasPrimaryFocus => _primaryEditor != null;

  static bool dismissPrimaryEditor() {
    final editor = _primaryEditor;
    if (editor == null || !editor._editing) {
      return false;
    }
    editor._finishTelevisionEditing();
    return true;
  }

  static _AppTvEditableFieldState? get _primaryEditor {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext is! Element) {
      return null;
    }
    _AppTvEditableFieldState? editor;
    focusContext.visitAncestorElements((element) {
      if (element case StatefulElement(:final state)
          when state is _AppTvEditableFieldState &&
              state._editing &&
              state._editorFocusNode.hasFocus) {
        editor = state;
        return false;
      }
      return true;
    });
    return editor;
  }

  @override
  State<AppTvEditableField> createState() => _AppTvEditableFieldState();
}

class _AppTvEditableFieldState extends State<AppTvEditableField> {
  static const _emptySummary = '—';
  static const _maskedSummary = '••••••••';

  late final FocusNode _editorFocusNode = FocusNode(
    debugLabel: 'app-tv-editable-field.editor',
  );
  var _editing = false;
  var _focusTransferEpoch = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppTvEditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.enabled && !widget.enabled && _editing) {
      _finishTelevisionEditing();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTenFoot = AppPresentationPolicy.maybeOf(context)?.isTenFoot ?? false;
    void completeEditing({FocusNode? nextFocusNode}) {
      if (isTenFoot) {
        _finishTelevisionEditing(nextFocusNode: nextFocusNode);
      } else if (nextFocusNode case final node?) {
        node.requestFocus();
      } else {
        widget.focusNode.unfocus();
      }
    }

    if (!isTenFoot) {
      return widget.builder(context, widget.focusNode, completeEditing);
    }

    return PopScope<void>(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _editing) {
          _finishTelevisionEditing();
        }
      },
      child: Stack(
        children: [
          Offstage(
            offstage: _editing,
            child: ExcludeFocus(
              excluding: _editing,
              child: _buildActivationSurface(context),
            ),
          ),
          Offstage(
            offstage: !_editing,
            child: TickerMode(
              enabled: _editing,
              child: ExcludeFocus(
                excluding: !_editing,
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: _handleEditorKeyEvent,
                  onFocusChange: _handleEditorRegionFocusChanged,
                  child: widget.builder(
                    context,
                    _editorFocusNode,
                    completeEditing,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationSurface(BuildContext context) {
    final tokens = context.presentationTokens;
    final summary = _summary;
    return Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      value: summary == _emptySummary ? null : summary,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(
            tokens.controlMinHeight,
            tokens.focusTargetMinSize,
          ),
        ),
        child: FButton.raw(
          key: widget.activationKey,
          variant: .outline,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onPress: widget.enabled ? _startEditing : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.cardGap,
              vertical: tokens.cardGap / 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.sm,
                      ),
                      Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.lg,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.cardGap),
                const Icon(FLucideIcons.pencil),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _summary {
    if (widget.controller.text.isEmpty) {
      return _emptySummary;
    }
    if (widget.secure) {
      return _maskedSummary;
    }
    final normalized = widget.controller.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? _emptySummary : normalized;
  }

  void _startEditing() {
    if (!widget.enabled || _editing) {
      return;
    }
    setState(() => _editing = true);
    _scheduleFocus(_editorFocusNode);
  }

  void _finishTelevisionEditing({FocusNode? nextFocusNode}) {
    if (_editing && mounted) {
      setState(() => _editing = false);
    }
    _scheduleFocus(nextFocusNode ?? widget.focusNode);
  }

  void _scheduleFocus(FocusNode node) {
    final epoch = ++_focusTransferEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && epoch == _focusTransferEpoch && node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void _handleEditorRegionFocusChanged(bool focused) {
    if (!focused && _editing) {
      _finishTelevisionEditing();
    }
  }

  KeyEventResult _handleEditorKeyEvent(FocusNode _, KeyEvent event) {
    final isDismissKey =
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.gameButtonB;
    if (!isDismissKey) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      _finishTelevisionEditing();
    }
    return KeyEventResult.handled;
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
