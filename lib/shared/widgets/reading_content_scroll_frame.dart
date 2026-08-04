import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// A centered, horizontally constrained scrollable frame for reading-style
/// screens (settings, accessibility, and similar long-form content).
///
/// Content is centered and constrained to [maxWidth], which defaults to the
/// presentation token's `readingContentMaxWidth` so the column scales on 10-foot
/// viewports. When [title] is provided it is rendered as a display heading above
/// [child] with a large vertical gap, matching the historical
/// `_SettingsScrollFrame` shape.
class ReadingContentScrollFrame extends StatelessWidget {
  const ReadingContentScrollFrame({
    required this.child,
    this.title,
    this.maxWidth,
    super.key,
  });

  /// Optional display heading rendered above [child]. When `null`, only
  /// [child] is shown.
  final String? title;

  /// Constrained reading-content width. Defaults to
  /// `context.presentationTokens.readingContentMaxWidth`.
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
