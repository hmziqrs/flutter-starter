import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A themed, single-line search input over ForUI's [FTextField].
///
/// The field owns no debounce timer — it fires [onChanged] on every keystroke
/// (and when the built-in clear affordance empties the field). The caller wires
/// [onChanged] to its feature-local debounced query controller
/// (`debouncedQueryProvider`); the debounce window lives there, not here, so
/// the field stays a pure presentational input reusable across surfaces (audit
/// #3: ≥3 consumers — search field, future filter rows, future command palettes).
///
/// RTL note: the leading search glyph and the trailing clear-X are mirrored
/// automatically by the ambient `Directionality` (audit #6); the query string
/// itself is direction-neutral.
///
/// Pure presentational widget: typed strings + callbacks, no state, no plugin,
/// no side effect beyond the caller's [onChanged]. The first concrete consumer
/// is `SearchPage`.
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

  /// Localized placeholder shown inside the field when it is empty (e.g.
  /// `search.placeholder`). Also used as the search glyph's semantic label so
  /// the icon is not announced twice (the hint text is the accessible name).
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
      // Leading search glyph. Decorative: the adjacent hint text is the
      // accessible name, so the icon carries the same string as its semantic
      // label only to satisfy the minimum-target / non-decorative rule when the
      // field is empty.
      prefixBuilder: (context, style, variants) =>
          Icon(FLucideIcons.search, semanticLabel: hintText),
      // Built-in clear-X: visible only when there is text to clear. Tapping it
      // empties the controller, which fires `onChange('')` so the caller's
      // debounce controller observes the cleared query.
      clearable: (value) => value.text.isNotEmpty,
      onSubmit: onSubmitted == null ? null : (_) => onSubmitted!(),
    );
  }
}
