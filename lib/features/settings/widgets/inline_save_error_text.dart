import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class InlineSaveErrorText extends StatelessWidget {
  const InlineSaveErrorText({
    required this.message,
    required this.valueKey,
    super.key,
  });

  final String message;

  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      key: ValueKey(valueKey),
      style: context.theme.typography.body.sm.copyWith(
        color: context.theme.colors.error,
      ),
    );
  }
}
