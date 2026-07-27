import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';

typedef AppKeyboardShortcutCallback = bool Function();

@immutable
final class AppKeyboardBinding {
  const AppKeyboardBinding({
    required this.activator,
    required this.onInvoke,
  });

  final ShortcutActivator activator;
  final AppKeyboardShortcutCallback onInvoke;
}

/// The app's single focus-independent keyboard listener and shortcut preview.
///
/// Mount this once at the root. Feature screens register no global hardware
/// handlers of their own; new app-wide bindings belong in root composition.
class AppKeyboardHost extends StatefulWidget {
  const AppKeyboardHost({
    required this.interactionPolicy,
    required this.bindings,
    required this.child,
    super.key,
  });

  final AppInteractionPolicy interactionPolicy;
  final List<AppKeyboardBinding> bindings;
  final Widget child;

  @override
  State<AppKeyboardHost> createState() => _AppKeyboardHostState();
}

class _AppKeyboardHostState extends State<AppKeyboardHost> {
  _AppKeyboardChord? _chord;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _dismissTimer?.cancel();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (_usesDirectionalFocus(widget.interactionPolicy) &&
        _isBackKey(event.logicalKey) &&
        (event is KeyDownEvent || event is KeyRepeatEvent) &&
        AppTvEditableField.editorHasPrimaryFocus) {
      if (event is KeyDownEvent) {
        AppTvEditableField.dismissPrimaryEditor();
      }
      return true;
    }

    if (event is KeyRepeatEvent &&
        _usesDirectionalFocus(widget.interactionPolicy) &&
        _isActivationKey(event.logicalKey)) {
      return true;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final chord = _AppKeyboardChord.fromKeyboard(HardwareKeyboard.instance);
      if (chord == null) {
        _clearChord();
      } else {
        _showChord(chord);
      }

      for (final binding in widget.bindings) {
        if (binding.activator.accepts(event, HardwareKeyboard.instance)) {
          return binding.onInvoke();
        }
      }
      return false;
    }

    if (event is KeyUpEvent && _isModifier(event.logicalKey)) {
      final chord = _AppKeyboardChord.fromKeyboard(HardwareKeyboard.instance);
      if (chord == null) {
        _scheduleDismiss();
      } else {
        _showChord(chord);
      }
    }
    return false;
  }

  void _showChord(_AppKeyboardChord chord) {
    _dismissTimer?.cancel();
    if (_chord == chord) {
      return;
    }
    setState(() => _chord = chord);
  }

  void _clearChord() {
    _dismissTimer?.cancel();
    if (_chord == null) {
      return;
    }
    setState(() => _chord = null);
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(AppMotion.keyboardChordHold, () {
      if (mounted) {
        _clearChord();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.quick;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: _usesDirectionalFocus(widget.interactionPolicy)
              ? Shortcuts(
                  debugLabel: 'AppKeyboardHost activation-repeat guard',
                  shortcuts: _activationRepeatShortcuts,
                  child: widget.child,
                )
              : widget.child,
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: context.spacing.xl),
            child: IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: animationDuration,
                  reverseDuration: animationDuration,
                  child: switch (_chord) {
                    final chord? => _AppKeyboardChordOverlay(
                      key: ValueKey(chord.labels),
                      chord: chord,
                    ),
                    null => const SizedBox.shrink(
                      key: ValueKey('app-keyboard-chord-empty'),
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

bool _usesDirectionalFocus(AppInteractionPolicy policy) {
  return policy == AppInteractionPolicy.remote || policy == AppInteractionPolicy.hybridRemote;
}

bool _isActivationKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.gameButtonA;
}

bool _isBackKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.gameButtonB;
}

const _activationRepeatShortcuts = <ShortcutActivator, Intent>{
  _ActivationRepeatActivator(LogicalKeyboardKey.enter): DoNothingAndStopPropagationIntent(),
  _ActivationRepeatActivator(LogicalKeyboardKey.numpadEnter): DoNothingAndStopPropagationIntent(),
  _ActivationRepeatActivator(LogicalKeyboardKey.space): DoNothingAndStopPropagationIntent(),
  _ActivationRepeatActivator(LogicalKeyboardKey.select): DoNothingAndStopPropagationIntent(),
  _ActivationRepeatActivator(LogicalKeyboardKey.gameButtonA): DoNothingAndStopPropagationIntent(),
};

@immutable
final class _ActivationRepeatActivator implements ShortcutActivator {
  const _ActivationRepeatActivator(this.trigger);

  final LogicalKeyboardKey trigger;

  @override
  Iterable<LogicalKeyboardKey> get triggers => <LogicalKeyboardKey>[trigger];

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    return event is KeyRepeatEvent && SingleActivator(trigger).accepts(event, state);
  }

  @override
  String debugDescribeKeys() => '${trigger.debugName ?? trigger.keyLabel} repeat';
}

class _AppKeyboardChordOverlay extends StatelessWidget {
  const _AppKeyboardChordOverlay({
    required this.chord,
    super.key,
  });

  final _AppKeyboardChord chord;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('app-keyboard-chord-overlay'),
      container: true,
      liveRegion: true,
      child: FCard(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < chord.labels.length; index++) ...[
                if (index > 0) ...[
                  SizedBox(width: context.spacing.xs),
                  Text('+', style: context.theme.typography.body.sm),
                  SizedBox(width: context.spacing.xs),
                ],
                FBadge(
                  key: ValueKey('app-keyboard-chord-key-$index'),
                  variant: .outline,
                  child: Text(chord.labels[index]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class _AppKeyboardChord {
  _AppKeyboardChord(List<String> labels) : labels = List.unmodifiable(labels);

  final List<String> labels;

  static _AppKeyboardChord? fromKeyboard(HardwareKeyboard keyboard) {
    final pressed = keyboard.logicalKeysPressed;
    final labels = <String>[
      if (keyboard.isMetaPressed) _metaLabel,
      if (keyboard.isControlPressed) _controlLabel,
      if (keyboard.isAltPressed) _altLabel,
      if (keyboard.isShiftPressed) _shiftLabel,
      if (pressed.contains(LogicalKeyboardKey.fn)) 'fn',
    ];
    if (labels.isEmpty) {
      return null;
    }

    final ordinaryKeys = pressed.where((key) => !_isModifier(key)).toList()
      ..sort((left, right) => left.keyId.compareTo(right.keyId));
    labels.addAll(ordinaryKeys.map(_ordinaryKeyLabel));
    return _AppKeyboardChord(labels);
  }

  static String get _metaLabel => defaultTargetPlatform == TargetPlatform.macOS ? '⌘' : 'Meta';
  static String get _controlLabel => defaultTargetPlatform == TargetPlatform.macOS ? '⌃' : 'Ctrl';
  static String get _altLabel => defaultTargetPlatform == TargetPlatform.macOS ? '⌥' : 'Alt';
  static String get _shiftLabel => defaultTargetPlatform == TargetPlatform.macOS ? '⇧' : 'Shift';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _AppKeyboardChord && listEquals(labels, other.labels);

  @override
  int get hashCode => Object.hashAll(labels);
}

bool _isModifier(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.meta ||
      key == LogicalKeyboardKey.metaLeft ||
      key == LogicalKeyboardKey.metaRight ||
      key == LogicalKeyboardKey.control ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.alt ||
      key == LogicalKeyboardKey.altLeft ||
      key == LogicalKeyboardKey.altRight ||
      key == LogicalKeyboardKey.shift ||
      key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight ||
      key == LogicalKeyboardKey.fn;
}

String _ordinaryKeyLabel(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.backspace) return '⌫';
  if (key == LogicalKeyboardKey.delete) return '⌦';
  if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) return '↵';
  if (key == LogicalKeyboardKey.escape) return 'Esc';
  if (key == LogicalKeyboardKey.tab) return '⇥';
  if (key == LogicalKeyboardKey.space) return 'Space';
  if (key == LogicalKeyboardKey.arrowLeft) return '←';
  if (key == LogicalKeyboardKey.arrowUp) return '↑';
  if (key == LogicalKeyboardKey.arrowRight) return '→';
  if (key == LogicalKeyboardKey.arrowDown) return '↓';

  final label = key.keyLabel;
  return label.length == 1 ? label.toUpperCase() : label;
}
