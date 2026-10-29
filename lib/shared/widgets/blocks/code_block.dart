import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/blocks/code_lines.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';

/// One version of the code an [AppCodeBlock] shows as a tab.
class AppCodeFile {
  const AppCodeFile({required this.label, required this.source});

  /// The tab's word, e.g. `Terminal` or `Cargo.toml`.
  final String label;

  /// The code the tab shows, and what its copy button puts on the clipboard.
  final String source;
}

/// The brand code block (BRAND.md s8): an outline with no fill, an optional
/// 40dp header bar carrying the file label or version tabs and a copy
/// button, and the source under it in JetBrains Mono 13 with the brand's
/// code colors.
///
/// Shiki has no Flutter equivalent, so the highlighting is the small Dart
/// tokenizer in `code_lines.dart` mapped onto the same `--code-*` roles.
/// No copy button on code people only read: pass [copyLabel] to add one. A
/// block with no bar carries its copy button floating at the block's top
/// right corner (code-block.svelte's `copy && !bar` branch), the way a bare
/// one-line command ships.
class AppCodeBlock extends StatefulWidget {
  const AppCodeBlock({
    this.source = '',
    this.label,
    this.copyLabel,
    this.files,
    super.key,
  });

  /// The code to show when [files] is null.
  final String source;

  /// The file label in the header bar, e.g. `main.dart`; omit for no bar.
  final String? label;

  /// The copy button's semantics label; when set, a copy button appears in
  /// the header bar — or, when there is no bar, floating at the block's top
  /// right corner.
  final String? copyLabel;

  /// Several versions of the same thing (Terminal / Cargo.toml) as tabs in
  /// the header bar. When set, [source] and [label] are ignored.
  final List<AppCodeFile>? files;

  @override
  State<AppCodeBlock> createState() => _AppCodeBlockState();
}

class _AppCodeBlockState extends State<AppCodeBlock> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final files = widget.files;
    final hasBar = files != null || widget.label != null;
    final source = files == null ? widget.source : files[_index.clamp(0, files.length - 1)].source;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (files != null)
            _TabBar(
              files: files,
              index: _index.clamp(0, files.length - 1),
              onSelected: (index) => setState(() => _index = index),
              trailing: widget.copyLabel == null
                  ? null
                  : AppCopyButton(text: source, label: widget.copyLabel!),
            )
          else if (widget.label != null)
            Container(
              height: 40,
              // The bar's own air (code-block.svelte: pl-3.5 pr-1.5); the
              // copy button brings the right-side hit target.
              padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colors.border)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.label!,
                      overflow: TextOverflow.ellipsis,
                      // The file label is a caption people read: Onest 12 in
                      // the muted foreground (code-block.svelte:
                      // text-xs text-muted-foreground). Mono stays in the
                      // code body below.
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (widget.copyLabel != null)
                    AppCopyButton(text: source, label: widget.copyLabel!),
                ],
              ),
            ),
          Stack(
            children: <Widget>[
              Padding(
                // The pre's air (code-block.svelte: px-4.5 py-4); with a
                // floating copy button the pre keeps 48dp clear on its end
                // (pr-12) so no line runs under it.
                padding: EdgeInsetsDirectional.only(
                  start: 18,
                  end: hasBar || widget.copyLabel == null ? 18 : 48,
                  top: 16,
                  bottom: 16,
                ),
                child: AppCodeLines(source: source),
              ),
              if (!hasBar && widget.copyLabel != null)
                // The bar-less block's copy button hangs 6dp from the top
                // right corner (code-block.svelte: top-1.5 right-1.5).
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: 6,
                  end: 6,
                  child: AppCopyButton(text: source, label: widget.copyLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The tabs bar: one pill per version, the selected one washed with the
/// foreground at 8% (code-block.svelte's tablist).
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.files,
    required this.index,
    required this.onSelected,
    required this.trailing,
  });

  final List<AppCodeFile> files;

  final int index;

  final ValueChanged<int> onSelected;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
      // The bar's air with the tab row's -ml-2 folded in: the pills' own
      // 10dp starts where code-block.svelte's do.
      padding: const EdgeInsetsDirectional.only(start: 6, end: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < files.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 4),
                  _Tab(
                    file: files[i],
                    selected: i == index,
                    onSelected: () => onSelected(i),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.file, required this.selected, required this.onSelected});

  final AppCodeFile file;

  final bool selected;

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onSelected,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // The tab pill: h-7 rounded-md px-2.5, text-xs; the selected one
        // carries the foreground at 8% and the text color
        // (aria-selected:bg-foreground/8 aria-selected:text-foreground).
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: AlignmentDirectional.center,
        decoration: ShapeDecoration(
          color: selected ? theme.colors.foreground.withValues(alpha: 0.08) : Colors.transparent,
          shape: RoundedSuperellipseBorder(borderRadius: theme.style.borderRadius.sm),
        ),
        child: Text(
          file.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body.xs.copyWith(
            color: selected ? theme.colors.foreground : theme.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
