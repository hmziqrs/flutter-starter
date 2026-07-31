import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';

class AppScreenFrame extends StatelessWidget {
  const AppScreenFrame({
    required this.child,
    this.scrollController,
    this.maxContentWidth,
    super.key,
  });

  final Widget child;
  final ScrollController? scrollController;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final framed = Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxContentWidth ?? context.presentationTokens.readingContentMaxWidth,
        ),
        child: child,
      ),
    );
    final controller = scrollController;
    if (controller == null) {
      return framed;
    }

    return SingleChildScrollView(
      controller: controller,
      child: framed,
    );
  }
}
