import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_switch_row.dart';

typedef SettingsToggleCallback<T> = Future<void> Function(T value);

/// Bridges a watched boolean preference onto a quiet [SettingsSwitchRow],
/// mapping a failed persistence write onto the row's inline soft error.
class SettingsToggleTile<T> extends ConsumerStatefulWidget {
  const SettingsToggleTile({
    required this.watch,
    required this.valueSelector,
    required this.onSave,
    required this.keyName,
    required this.label,
    this.description,
    this.statusText,
    super.key,
  });

  final T Function(WidgetRef ref) watch;

  final bool Function(T value) valueSelector;

  final SettingsToggleCallback<bool> onSave;

  final String keyName;

  final String label;

  final String? description;

  final String? statusText;

  @override
  ConsumerState<SettingsToggleTile<T>> createState() => _SettingsToggleTileState<T>();
}

class _SettingsToggleTileState<T> extends ConsumerState<SettingsToggleTile<T>>
    with SettingsSaveFailureState<SettingsToggleTile<T>> {
  @override
  Widget build(BuildContext context) {
    final value = widget.valueSelector(widget.watch(ref));
    return SettingsSwitchRow(
      keyName: widget.keyName,
      label: widget.label,
      description: widget.description,
      statusText: widget.statusText,
      value: value,
      onChange: (next) => runSave(() => widget.onSave(next)),
      saveFailed: saveFailed,
    );
  }
}
