import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';
import 'package:starter/shared/widgets/rings/horizon_rings.dart';

/// A horizon band that reveals with scroll position: the one place
/// scroll-linked motion is allowed (BRAND.md s10).
///
/// The picture — sun, rings, glints, stars — fades in piece by piece as the
/// user scrolls, and back out on the way up; nothing animates on its own.
/// Without a scrollable ancestor it draws the whole picture. Reduced motion
/// skips the reveal and always draws the whole still picture. Listens to
/// [controller] when given, otherwise to the nearest [Scrollable]; the same
/// [ScrollRings.seed] always draws the same picture. Decorative: pass
/// [ScrollRings.semanticsLabel] to describe the picture, otherwise it is
/// excluded from semantics.
class ScrollRings extends StatefulWidget {
  const ScrollRings({
    required this.seed,
    this.controller,
    this.awake = true,
    this.revealSpan = 0.5,
    this.semanticsLabel,
    super.key,
  });

  /// The site's or project's name.
  final String seed;

  /// The scroll position to follow; defaults to the nearest scrollable.
  final ScrollController? controller;

  /// Whether the sun is up; asleep, the sun goes out and stars come up.
  final bool awake;

  /// How much scrolling (in viewport heights) the full reveal takes.
  final double revealSpan;

  /// What the picture shows, for screen readers.
  final String? semanticsLabel;

  @override
  State<ScrollRings> createState() => _ScrollRingsState();
}

class _ScrollRingsState extends State<ScrollRings> {
  ScrollPosition? _position;

  final ValueNotifier<double> _reveal = ValueNotifier<double>(0);

  late List<HorizonArc> _arcs;

  late List<(Offset, double)> _stars;

  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _draw();
    widget.controller?.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _attach(widget.controller?.position ?? Scrollable.maybeOf(context)?.position);
    _onScroll();
  }

  @override
  void didUpdateWidget(ScrollRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _draw();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      widget.controller?.addListener(_onScroll);
    }
    _attach(widget.controller?.position ?? Scrollable.maybeOf(context)?.position);
  }

  void _attach(ScrollPosition? position) {
    if (identical(position, _position)) {
      return;
    }
    _position?.removeListener(_onScroll);
    _position = position;
    position?.addListener(_onScroll);
    _onScroll();
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    widget.controller?.removeListener(_onScroll);
    _reveal.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _position;
    // Nothing has scrolled into view yet: the picture waits at zero until
    // the position knows its dimensions. Reduced motion shows the whole
    // still picture, and so does having no scrollable to follow.
    var fraction = 0.0;
    if (_reducedMotion || position == null) {
      fraction = 1.0;
    } else if (position.hasContentDimensions &&
        position.hasViewportDimension &&
        position.viewportDimension > 0) {
      fraction = (position.pixels / (position.viewportDimension * widget.revealSpan)).clamp(
        0.0,
        1.0,
      );
    }
    _reveal.value = fraction;
  }

  void _draw() {
    _arcs = horizonArcs(
      widget.seed,
      cx: HorizonRingsPainter.center.dx,
      cy: HorizonRingsPainter.center.dy,
      radii: <double>[for (var i = 0; i < 10; i += 1) 46.0 + 24 * i],
      accent: 2,
    );
    _stars = horizonStars(widget.seed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    Widget picture = CustomPaint(
      painter: HorizonRingsPainter(
        arcs: _arcs,
        stars: _stars,
        lineColor: theme.brand.line,
        accentColor: theme.colors.primary,
        foregroundColor: theme.colors.foreground,
        awakeMix: widget.awake ? 1 : 0,
        revealListenable: _reveal,
        repaint: _reveal,
      ),
    );
    final label = widget.semanticsLabel;
    if (label != null) {
      picture = Semantics(label: label, image: true, child: picture);
    } else {
      picture = ExcludeSemantics(child: picture);
    }
    return AspectRatio(
      aspectRatio: HorizonRingsPainter.viewBox.aspectRatio,
      child: picture,
    );
  }
}
