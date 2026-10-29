import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// A tab strip whose active tab carries a brand-material quad (the
/// shader-kit variant of the line tabs): the pill keeps the thin theme line,
/// and the selection shows as the one place the material appears — feedback
/// is color only, nothing moves.
class MaterialTabs extends StatelessWidget {
  const MaterialTabs({
    required this.recipe,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabel,
    super.key,
  });

  /// The material behind the active tab's label; one recipe for the whole
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var index = 0; index < tabs.length; index++)
                _MaterialTab(
                  label: tabs[index],
                  selected: index == selectedIndex,
                  recipe: recipe,
                  onTap: () => onSelected(index),
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
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: ShapeDecoration(
              color: _hovering && !widget.selected ? theme.colors.muted : Colors.transparent,
              shape: RoundedSuperellipseBorder(
                borderRadius: theme.style.borderRadius.md,
              ),
            ),
            child: widget.selected
                ? _MaterialLabel(label: widget.label, recipe: widget.recipe)
                : Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.sm.copyWith(
                      color: _hovering || _focused
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The selected tab's label over its material quad; the label sizes the
/// quad, and the material fills behind it.
class _MaterialLabel extends StatelessWidget {
  const _MaterialLabel({required this.label, required this.recipe});

  final String label;

  final BrandMaterialRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.sm.resolve(Directionality.of(context));
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: BrandMaterialSurface(recipe: recipe)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.sm.copyWith(
                // Text over the material reads in the on-orange token, the
                // one color designed to sit on the brand's saturated fills
                // (BRAND.md s4).
                color: theme.brand.onOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
