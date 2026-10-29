import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A tab strip whose selection carries a thin brand-material bar (the
/// shader-kit variant of the kit's line tabs): every tab keeps its text on
/// the page color and a 2px rule under it — the theme line at rest, the
/// material under the selected one — the way the kit's tabs mark selection
/// with a border accent and never put words on raw metal (BRAND.md s13).
///
/// Feedback is color only, nothing moves.
class MaterialTabs extends StatelessWidget {
  const MaterialTabs({
    required this.recipe,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabel,
    super.key,
  });

  /// The material in the selected tab's accent bar; one recipe for the whole
  /// strip — the selection moves it, it never re-themes per tab.
  final BrandMaterialRecipe recipe;

  /// Tab labels, in order. Sentence case comes from the caller.
  final List<String> tabs;

  /// The zero-based active tab.
  final int selectedIndex;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onSelected;

  /// What screen readers call the whole row, e.g. "Views".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      container: semanticLabel != null,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
            borderRadius: theme.style.borderRadius.lg,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Bottom-aligned rather than stretched: stretch asserts under the
          // unbounded height a vertical scrollable hands this strip, and the
          // single-line labels keep every tab the same height anyway.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (var index = 0; index < tabs.length; index++)
                // Each tab hugs its label's intrinsic width; the tab's inner
                // stretch needs that bounded width (the scroll view hands the
                // row unbounded width) for its full-width selection rule.
                IntrinsicWidth(
                  child: _MaterialTab(
                    label: tabs[index],
                    selected: index == selectedIndex,
                    recipe: recipe,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialTab extends StatefulWidget {
  const _MaterialTab({
    required this.label,
    required this.selected,
    required this.recipe,
    required this.onTap,
  });

  final String label;

  final bool selected;

  final BrandMaterialRecipe recipe;

  final VoidCallback onTap;

  @override
  State<_MaterialTab> createState() => _MaterialTabState();
}

class _MaterialTabState extends State<_MaterialTab> {
  bool _hovering = false;
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FocusableActionDetector(
      focusNode: _focusNode,
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (hovering) => setState(() => _hovering = hovering),
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        selected: widget.selected,
        button: true,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            // The label stays on the page color; the material lives only in
            // the 2px rule under the selected tab (the kit's border accent).
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.sm.copyWith(
                      color: widget.selected || _hovering || _focused
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: 2,
                  child: widget.selected
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: BrandMaterialSurface(recipe: widget.recipe),
                        )
                      : ColoredBox(color: theme.colors.border),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
