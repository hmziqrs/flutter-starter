import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class ReadingContentScrollFrame extends StatelessWidget {
  const ReadingContentScrollFrame({
    required this.child,
    this.title,
    this.maxWidth,
    super.key,
  });

  final String? title;

  final double? maxWidth;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        context.spacing.xl,
        context.spacing.xl,
        context.spacing.xl,
        context.spacing.xl2,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? context.presentationTokens.readingContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  Text(title!, style: context.theme.typography.display.xl2),
                  SizedBox(height: context.spacing.xl),
                ],
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
