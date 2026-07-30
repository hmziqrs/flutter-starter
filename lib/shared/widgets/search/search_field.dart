import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A themed, single-line search input over ForUI's [FTextField].
///
/// The field owns no debounce timer — it fires [onChanged] on every keystroke
/// (and when the built-in clear affordance empties the field). The caller
/// wires [onChanged] to its own debounced query controller; the debounce
/// window lives there, not here.
class SearchField extends StatelessWidget {
  /// Creates a [SearchField].
  const SearchField({
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.focusNode,
    this.onSubmitted,
    super.key,
  });

  /// The text controller backing the input. Owned by the caller (the page),
  /// so it can pre-fill the field and read the raw value for accessibility.
  final TextEditingController controller;

  /// Fires with the current field text on every keystroke and when the clear
  /// affordance empties the field. Wire this to the feature-local debounced
  /// query controller.
  final ValueChanged<String> onChanged;

  /// Localized placeholder shown inside the field when it is empty. Also used
  /// as the search glyph's semantic label.
  final String hintText;

  /// Optional focus node. The caller may request focus on mount.
  final FocusNode? focusNode;

  /// Optional submit callback — fired when the user presses the keyboard's
  /// search action. The caller may use this to clear focus.
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return FTextField(
      key: const ValueKey('search-field'),
      control: .managed(
        controller: controller,
        onChange: (value) => onChanged(value.text),
      ),
      focusNode: focusNode,
      hint: hintText,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      prefixBuilder: (context, style, variants) =>
          Icon(FLucideIcons.search, semanticLabel: hintText),
      clearable: (value) => value.text.isNotEmpty,
      onSubmit: onSubmitted == null ? null : (_) => onSubmitted!(),
    );
  }
}
