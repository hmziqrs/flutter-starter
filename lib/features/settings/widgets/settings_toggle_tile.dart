import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';

typedef SettingsToggleCallback<T> = Future<void> Function(T value);

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

  final T Function(WidgetRef ref) watch;

  final bool Function(T value) valueSelector;

  final SettingsToggleCallback<bool> onSave;

  final String keyName;

  final Widget label;

  final Widget? description;

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
