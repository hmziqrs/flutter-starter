import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/band_arcs.dart';

/// The orange closing band (`.band-orange`, BRAND.md s7 "Bands" and s8
/// "Closing call to action"): a full-width solid oxide section with square
/// edges, band arcs on the right from md up, and content whose colors flip
/// to on-orange — the heading and sentence in the on-orange text color, the
/// main button filled with it and the outline button drawn in it.
///
/// Inside the band the brand tokens retune like the web's `.band-orange`
/// class: the rings' hairline (`--line`) becomes on-orange at 20% so the
/// faint arcs read dark on the orange next to the dark accent ring. Below
/// md the arcs sit out (rings never render behind text, BRAND.md s13).
///
/// At most one per screen: this is the page's loudest section and the only
/// solid orange fill behind text (BRAND.md s4). Strings and actions come
/// from the caller — the band hardcodes no copy. Feedback is color only;
/// nothing moves on hover or press (BRAND.md s10).
class CtaBand extends StatelessWidget {
  const CtaBand({
    required this.heading,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    super.key,
  });

  /// The band's heading, one line if it fits.
  final String heading;

  /// One sentence under the heading.
  final String message;

  /// The main action's label; it says what happens.
  final String primaryLabel;

  /// The second action's label; it says what happens.
  final String secondaryLabel;

  final VoidCallback? onPrimaryPressed;

  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final brand = context.theme.brand;
    final band = brand.oxide;
    final onBand = brand.onOrange;
    return ColoredBox(
      color: band,
      // .band-orange redefines the tokens inside itself (BRAND.md s3): the
      // rings' --line becomes on-orange at 20%, so BandArcs' faint rings
      // resolve band-aware without the widget knowing it sits on a band.
      child: FTheme(
        data: _bandThemeData(context, brand),
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 768;
              return Stack(
                children: <Widget>[
                  // Band arcs on the right from md up (s7): 170% of the band
                  // height, hugging the right edge and bleeding off it; the
                  // clip keeps them inside the band. Below md they sit out —
                  // the arc square is wider than the band, and rings never
                  // render behind text (s13).
                  if (wide)
                    Positioned.fill(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FractionallySizedBox(
                          heightFactor: 1.7,
                          alignment: AlignmentDirectional.centerEnd,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: BandArcs(accentColor: onBand),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: wide ? 96 : 64, horizontal: 24),
                    child: Align(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1024),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              heading,
                              style: TextStyle(
                                fontSize: wide ? 52 : 36,
                                height: 1.02,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.04 * (wide ? 52 : 36),
                                color: onBand,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Text(
                                message,
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.625,
                                  color: onBand,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                _BandButton.filled(
                                  label: primaryLabel,
                                  onPressed: onPrimaryPressed,
                                  fill: onBand,
                                  content: band,
                                  hoverWash: onBand.withValues(alpha: 0.88),
                                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                                ),
                                _BandButton.outline(
                                  label: secondaryLabel,
                                  onPressed: onSecondaryPressed,
                                  content: onBand,
                                  hoverWash: onBand.withValues(alpha: 0.12),
                                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The band's retuned theme data (.band-orange's token redefinition): the
/// ambient theme with the brand extension's ring hairline set to on-orange
/// at 20%, every other extension kept as is.
FThemeData _bandThemeData(BuildContext context, AppBrandColors brand) {
  final theme = context.theme;
  final bandBrand = brand.copyWith(line: brand.onOrange.withValues(alpha: 0.2));
  final extensions = List<ThemeExtension<dynamic>>.of(theme.extensions);
  var replaced = false;
  for (var i = 0; i < extensions.length; i++) {
    if (extensions[i] is AppBrandColors) {
      extensions[i] = bandBrand;
      replaced = true;
    }
  }
  if (!replaced) {
    extensions.add(bandBrand);
  }
  return theme.copyWith(extensions: extensions);
}

/// A band button: color-only feedback, no motion, 40px tall, real button
/// semantics from the underlying Material control.
class _BandButton extends StatelessWidget {
  const _BandButton.filled({
    required this.label,
    required this.onPressed,
    required this.fill,
    required this.content,
    required this.hoverWash,
    required this.fontFamily,
  }) : _outline = false;

  const _BandButton.outline({
    required this.label,
    required this.onPressed,
    required this.content,
    required this.hoverWash,
    required this.fontFamily,
  }) : _outline = true,
       fill = null;

  final String label;
  final VoidCallback? onPressed;
  final Color content;
  final Color hoverWash;

  /// The filled variant's fill color; null draws the outline variant.
  final Color? fill;
  final bool _outline;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));
    const shape = WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radius));
    final labelStyle = WidgetStatePropertyAll(
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: fontFamily),
    );
    final backgroundColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return _outline ? null : fill?.withValues(alpha: 0.5);
      }
      if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
        return hoverWash;
      }
      return _outline ? Colors.transparent : fill;
    });
    final side = WidgetStatePropertyAll(
      _outline ? BorderSide(color: content.withValues(alpha: 0.45)) : BorderSide.none,
    );
    final style = ButtonStyle(
      backgroundColor: backgroundColor,
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return _outline ? content.withValues(alpha: 0.5) : content;
        }
        return content;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(64, 40)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24)),
      shape: shape,
      side: side,
      textStyle: labelStyle,
    );
    Widget button;
    if (_outline) {
      button = OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
    } else {
      button = ElevatedButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return button;
  }
}
