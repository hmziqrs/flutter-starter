import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.focusNode,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;

  final ValueChanged<String> onChanged;

  final String hintText;

  final FocusNode? focusNode;

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
      // Brand text field: a line, no fill — the theme border and its
      // primary focus border stay, only the card-colored fill is cleared.
      style: .delta(
        color: .delta([.base(null), .variants(null)]),
      ),
      prefixBuilder: (context, style, variants) => FTextField.prefixIconBuilder(
        context,
        style,
        variants,
        Icon(FLucideIcons.search, semanticLabel: hintText),
      ),
      clearable: (value) => value.text.isNotEmpty,
      onSubmit: onSubmitted == null ? null : (_) => onSubmitted!(),
    );
  }
}
