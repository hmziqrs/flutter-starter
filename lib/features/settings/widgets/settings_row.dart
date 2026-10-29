import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// A quiet navigation row: an optional muted icon, a 14 w500 label, an
/// optional muted description, and a muted directional chevron.
///
/// Icons sit at the brand's default 16px — the size for icons next to body
/// text (BRAND.md s6); 18px is reserved for icon tiles.
///
/// Destructive rows (sign out) tint their label, icon and chevron with the
/// destructive role and hover on the role's soft fill — never a solid red
/// panel (BRAND.md s4). Feedback is color only (BRAND.md s10).
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    required this.label,
    required this.onPress,
    this.rowKey,
    this.leading,
    this.description,
    this.destructive = false,
    super.key,
  });

  /// The row's [Key]; keeps test and semantics hooks stable.
  final Key? rowKey;

  /// What the row is called; also its accessible name.
  final String label;

  /// One muted sentence under the label.
  final String? description;

  /// A leading icon, at the text color of the row.
  final IconData? leading;

  /// Red text on the soft destructive fill on hover; never a solid panel.
  final bool destructive;

  /// Where the row goes, or what it does.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = destructive ? theme.brand.destructive : theme.colors.foreground;
    return _PressableRow(
      rowKey: rowKey,
      label: label,
      onPress: onPress,
      destructive: destructive,
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: 16, color: destructive ? color : theme.colors.mutedForeground),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _LabelText(label: label, description: description, color: color),
          ),
          const SizedBox(width: 12),
          _DirectionalChevron(color: destructive ? color : theme.colors.mutedForeground),
        ],
      ),
    );
  }
}

/// A quiet option row picked with the brand's ring marker: the ring fills
/// when the option is on (BRAND.md s7 — filled means on, open or selected).
class SettingsOptionRow extends StatelessWidget {
  const SettingsOptionRow({
    required this.label,
    required this.selected,
    required this.onPress,
    this.rowKey,
    this.description,
    super.key,
  });

  /// The row's [Key]; keeps test and semantics hooks stable.
  final Key? rowKey;

  /// What the option is called; also its accessible name.
  final String label;

  /// One muted sentence under the label.
  final String? description;

  /// Filled marker means picked.
  final bool selected;

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return _PressableRow(
      rowKey: rowKey,
      label: label,
      onPress: onPress,
      selected: selected,
      child: Row(
        children: [
          Expanded(
            child: _LabelText(
              label: label,
              description: description,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(width: 12),
          AppRingMarker(
            filled: selected,
            color: selected ? theme.colors.primary : theme.colors.mutedForeground,
          ),
        ],
      ),
    );
  }
}

/// A quiet row that states a machine value (a build label): JetBrains Mono
/// for the value (BRAND.md s5 — mono is for code and machine values only),
/// muted because it is metadata, not an action.
class SettingsValueRow extends StatelessWidget {
  const SettingsValueRow({required this.label, required this.value, super.key});

  /// What the value is called.
  final String label;

  /// The machine value, in mono.
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: _rowPadding,
      child: Row(
        children: [
          Expanded(
            child: _LabelText(label: label, description: null, color: theme.colors.foreground),
          ),
          const SizedBox(width: 12),
          // Flexible so a long value (a long localized string, or the
          // gallery's placeholder sentence) ellipsizes instead of pushing
          // the row past its width.
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _rowPadding = EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14);

class _LabelText extends StatelessWidget {
  const _LabelText({required this.label, required this.description, required this.color});

  final String label;
  final String? description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.typography.body.sm.copyWith(color: color, fontWeight: FontWeight.w500),
        ),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ],
    );
  }
}

class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Directionality.of(context) == TextDirection.rtl
          ? FLucideIcons.chevronLeft
          : FLucideIcons.chevronRight,
      // 16px: the default for icons next to body text (BRAND.md s6).
      size: 16,
      color: color,
    );
  }
}

/// The shared body of a quiet pressable row: hover fills with the muted
/// surface (the destructive role's soft fill on destructive rows), focus
/// draws the primary ring, Enter and Space activate, and nothing ever
/// moves (BRAND.md s10).
class _PressableRow extends StatefulWidget {
  const _PressableRow({
    required this.label,
    required this.onPress,
    required this.child,
    this.rowKey,
    this.destructive = false,
    this.selected = false,
  });

  final Key? rowKey;
  final String label;
  final bool destructive;
  final bool selected;
  final VoidCallback onPress;
  final Widget child;

  @override
  State<_PressableRow> createState() => _PressableRowState();
}

class _PressableRowState extends State<_PressableRow> {
  bool _hovering = false;
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode(debugLabel: 'settings.row.${widget.label}');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final destructive = widget.destructive;
    final hoverFill = destructive
        ? theme.brand.destructive.withValues(
            alpha: theme.colors.brightness == Brightness.dark ? 0.20 : 0.10,
          )
        : theme.colors.muted;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onPress,
      child: FocusableActionDetector(
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
              widget.onPress();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPress,
          behavior: HitTestBehavior.opaque,
          child: Container(
            key: widget.rowKey,
            padding: _rowPadding,
            decoration: ShapeDecoration(
              color: _hovering ? hoverFill : Colors.transparent,
              shape: RoundedSuperellipseBorder(
                side: _focused
                    ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                    : BorderSide.none,
                borderRadius: theme.style.borderRadius.sm,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
