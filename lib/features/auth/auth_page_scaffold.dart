import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/blocks/page_header.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';

/// Shared presentation helpers for the entry-flow screens (APP-BLOCKS type
/// scale): page titles at 24 w500 tracking-tight (tracking-tight = -0.025em,
/// the kit page intro's recipe) and muted 14 descriptions.
///
/// The app theme already carries the Onest faces and the w500 display weight;
/// these helpers only pin the scale so pages built on the raw generated theme
/// (tests, previews) read the same.
TextStyle entryPageTitleStyle(BuildContext context) {
  final typography = context.theme.typography;
  final fontSize = typography.display.xl.fontSize ?? 24;
  return typography.display.xl.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: -fontSize * 0.025,
  );
}

TextStyle entryMutedBodyStyle(BuildContext context) {
  return context.theme.typography.body.sm.copyWith(
    color: context.theme.colors.mutedForeground,
  );
}

/// The frame of an entry-flow page (auth-layout.svelte): no shell and no nav,
/// just one small column holding the wordmark, the title, and the form.
///
/// On expanded windows it is the kit's split variant, with the column on the
/// start side and the product's rings behind a hairline on the end side. The
/// rings never carry text. Smaller windows get the centered variant, the same
/// column without the rings.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.screenId,
    required this.layoutClass,
    required this.title,
    required this.body,
    required this.form,
    this.titleKey,
    this.bodyKey,
    super.key,
  });

  final String screenId;
  final AppLayoutClass layoutClass;
  final String title;
  final String body;
  final Widget form;
  final Key? titleKey;
  final Key? bodyKey;

  /// The kit's `max-w-sm` column.
  static const double columnMaxWidth = 384;

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      key: ValueKey('auth-$screenId-page'),
      childPad: false,
      child: SafeArea(
        child: switch (layoutClass) {
          AppLayoutClass.compact => _Column(
            key: ValueKey('auth-$screenId-layout-compact'),
            scaffold: this,
            storageKey: 'auth-$screenId-layout-compact',
          ),
          AppLayoutClass.medium => _Column(
            key: ValueKey('auth-$screenId-layout-medium'),
            scaffold: this,
            storageKey: 'auth-$screenId-layout-medium',
          ),
          AppLayoutClass.expanded => Row(
            key: ValueKey('auth-$screenId-layout-expanded'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Column(
                  scaffold: this,
                  storageKey: 'auth-$screenId-expanded-form',
                  key: ValueKey('auth-$screenId-expanded-form'),
                ),
              ),
              Expanded(child: _RingsAside(seed: screenId)),
            ],
          ),
        },
      ),
    );
  }
}

/// The column: brand, then the title block, then the form. Scrolls when the
/// keyboard or a large text setting needs more room than the window has, and
/// stays vertically centered otherwise (`md:justify-center`).
class _Column extends StatelessWidget {
  const _Column({required this.scaffold, required this.storageKey, super.key});

  final AuthPageScaffold scaffold;
  final String storageKey;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: PageStorageKey(storageKey),
        padding: EdgeInsetsDirectional.fromSTEB(
          spacing.lg,
          spacing.xl2,
          spacing.lg,
          spacing.xl2 + media.viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: scaffold.layoutClass == AppLayoutClass.compact
                ? 0
                : (constraints.maxHeight - 2 * spacing.xl2).clamp(0, double.infinity),
          ),
          child: Align(
            alignment: scaffold.layoutClass == AppLayoutClass.compact
                ? AlignmentDirectional.topStart
                : AlignmentDirectional.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AuthPageScaffold.columnMaxWidth),
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppWordmark(name: context.t.app.name),
                    ),
                    SizedBox(height: spacing.xl2 + spacing.sm),
                    AppPageHeader(
                      title: scaffold.title,
                      description: scaffold.body,
                      titleKey: scaffold.titleKey,
                      descriptionKey: scaffold.bodyKey,
                      gap: spacing.sm,
                    ),
                    SizedBox(height: spacing.xl2),
                    scaffold.form,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The split layout's art: the product's rings on the page color, behind a
/// hairline. Decorative only; the meaning stays in the column.
class _RingsAside extends StatelessWidget {
  const _RingsAside({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.xl3),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: BrandRings(seed: 'auth $seed'),
            ),
          ),
        ),
      ),
    );
  }
}
