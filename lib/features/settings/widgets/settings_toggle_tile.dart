import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';

/// Signature for a toggle persistence call invoked when the switch changes.
///
/// Generic over the value ([bool] for the toggle's new state) so the parameter
/// can be declared without a concrete `bool`, which keeps the
/// `avoid_positional_boolean_parameters` lint satisfied at the declaration site.
typedef SettingsToggleCallback<T> = Future<void> Function(T value);

/// A generic boolean settings toggle that collapses the watch / save-failure
/// scaffolding shared by the simple toggle tiles.
///
/// The tile reads its current value by invoking [watch] against the widget's
/// [WidgetRef] (typically `ref.watch` on a settings controller), extracts the
/// boolean via [valueSelector], and forwards changes to [onSave]. [onSave] is
/// wrapped in the shared save-failure handler so persistence failures surface
/// as the inline `settings-toggle-save-error` text rendered by
/// [SettingsToggleCard]. All visual parameters are passed straight through to
/// [SettingsToggleCard].
///
/// Tiles that need a conditional guard before saving (for example the
/// biometric-availability or passcode-enabled checks) should keep a dedicated
/// [ConsumerStatefulWidget] and drive [SettingsToggleCard] directly instead of
/// using this widget.
///
/// Note: a `ProviderListenable<T>` field would be the most expressive shape,
/// but riverpod 3.x keeps that type internal, so [watch] accepts the [WidgetRef]
/// directly — callers pass `(ref) => ref.watch(myProvider)`.
class SettingsToggleTile<T> extends ConsumerStatefulWidget {
  const SettingsToggleTile({
    required this.watch,
    required this.valueSelector,
    required this.onSave,
    required this.keyName,
    required this.label,
    this.description,
    this.status,
    super.key,
  });

  /// Watches the backing provider and returns its current value, e.g.
  /// `(ref) => ref.watch(settingsControllerProvider)`.
  final T Function(WidgetRef ref) watch;

  /// Extracts the toggle's boolean from the watched value.
  final bool Function(T value) valueSelector;

  /// Invoked with the new switch value when the user toggles it. The tile wraps
  /// this in its save-failure handler, so callers should pass the raw
  /// persistence call (e.g. `controller.setXxx(enabled: value)`).
  final SettingsToggleCallback<bool> onSave;

  /// Forwarded to [SettingsToggleCard.keyName].
  final String keyName;

  /// Forwarded to [SettingsToggleCard.label].
  final Widget label;

  /// Forwarded to [SettingsToggleCard.description].
  final Widget? description;

  /// Forwarded to [SettingsToggleCard.status].
  final String? status;

  @override
  ConsumerState<SettingsToggleTile<T>> createState() => _SettingsToggleTileState<T>();
}

class _SettingsToggleTileState<T> extends ConsumerState<SettingsToggleTile<T>>
    with SettingsSaveFailureState<SettingsToggleTile<T>> {
  @override
  Widget build(BuildContext context) {
    final value = widget.valueSelector(widget.watch(ref));
    return SettingsToggleCard(
      keyName: widget.keyName,
      label: widget.label,
      description: widget.description,
      status: widget.status,
      value: value,
      onChange: (next) => runSave(() => widget.onSave(next)),
      saveFailed: saveFailed,
    );
  }
}
