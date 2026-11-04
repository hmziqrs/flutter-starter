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
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
    // The kit's page frame: `px-4 py-6`, `md:px-8 md:py-8` from the medium width.
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final side = wide ? spacing.xl2 : spacing.lg;
    final top = wide ? spacing.xl2 : spacing.xl;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(side, top, side, spacing.xl2),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? tokens.readingContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  Text(title!, style: context.theme.typography.display.xl2),
                  SizedBox(height: spacing.xl),
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
