import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';

/// The hero rings drawing themselves as they scroll into view (the kits'
/// `scroll-rings`): the same seeded picture as [BrandRings] — eleven rings
/// around (440, 225) drawn from [ScrollRings.seed] — with each ring's dash
/// growing from nothing, one after another, the accent ring last and its dot
/// appearing at the very end.
///
/// The draw follows the scroll position (the kit's `animation-timeline:
/// view()`): [ScrollRings.revealSpan] viewports of scrolling take the whole
/// draw. Without a scrollable ancestor, before the position knows its
/// dimensions, or under reduced motion, the picture draws fully — the kit's
/// `@supports` fallback. Decorative: pass [ScrollRings.semanticsLabel] to
/// describe the picture, otherwise it is excluded from semantics.
class ScrollRings extends StatefulWidget {
  const ScrollRings({
    required this.seed,
    this.controller,
    this.revealSpan = 0.5,
    this.semanticsLabel,
    super.key,
  });

  /// The site's or project's name.
  final String seed;

  /// The scroll position to follow; defaults to the nearest scrollable.
  final ScrollController? controller;

  /// How much scrolling (in viewport heights) the full draw takes.
  final double revealSpan;

  /// What the picture shows, for screen readers.
  final String? semanticsLabel;

  @override
  State<ScrollRings> createState() => _ScrollRingsState();
}

class _ScrollRingsState extends State<ScrollRings> {
  ScrollPosition? _position;

  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  late List<RingArc> _arcs;

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
    _progress.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _position;
    // Nothing has scrolled into view yet: the picture waits at zero until
    // the position knows its dimensions. Reduced motion shows the whole
    // drawn picture, and so does having no scrollable to follow.
    var progress = 0.0;
    if (_reducedMotion || position == null) {
      progress = 1.0;
    } else if (position.hasContentDimensions &&
        position.hasViewportDimension &&
        position.viewportDimension > 0) {
      progress = (position.pixels / (position.viewportDimension * widget.revealSpan)).clamp(
        0.0,
        1.0,
      );
    }
    _progress.value = progress;
  }

  void _draw() {
    _arcs = heroRings(widget.seed).arcs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    Widget picture = CustomPaint(
      painter: ScrollRingsPainter(
        arcs: _arcs,
        progress: _progress,
        lineColor: theme.brand.line,
        accentColor: theme.colors.primary,
      ),
    );
    final label = widget.semanticsLabel;
    if (label != null) {
      picture = Semantics(label: label, image: true, child: picture);
    } else {
      picture = ExcludeSemantics(child: picture);
    }
    return AspectRatio(aspectRatio: ScrollRingsPainter.viewBox.aspectRatio, child: picture);
  }
}

/// Paints the hero picture with each ring's dash growing with scroll
/// progress, in the kits' 520x440 viewBox.
///
/// The draw windows are the kit's `animation-range` values: the accent ring
/// draws over progress 34-46%, faint ring *i* over `4 + 2.5 * i`% to
/// `22 + 2.5 * i`%, and the accent dot fades in over 45-48%.
class ScrollRingsPainter extends CustomPainter {
  // The listenable keeps a public name at the call site, unlike the
  // codebase's private initializing formals.
  ScrollRingsPainter({
    required this.arcs,
    required ValueListenable<double> progress,
    required this.lineColor,
    required this.accentColor,
  }) : _progress = progress; // ignore: prefer_initializing_formals

  /// The rings to draw, in viewBox units, as [heroRings] returns them.
  final List<RingArc> arcs;

  final ValueListenable<double> _progress;

  final Color lineColor;

  final Color accentColor;

  static const Size viewBox = Size(520, 440);

  static const Offset center = Offset(440, 225);

  /// The progress value the painter draws at, for tests.
  @visibleForTesting
  double get progressValue => _progress.value;

  double _window(double progress, double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox.width;
    final progress = _progress.value;
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(scale);
    for (final (index, arc) in arcs.indexed) {
      final start = arc.accent ? 0.34 : 0.04 + index * 0.025;
      final end = arc.accent ? 0.46 : 0.22 + index * 0.025;
      final share = _window(progress, start, end);
      if (share <= 0) {
        continue;
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arc.radius),
        arc.rotateDegrees * math.pi / 180,
        share * arc.drawn / arc.radius,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = arc.accent ? 3 : 1.25
          ..strokeCap = StrokeCap.round
          ..color = arc.accent ? accentColor : lineColor,
      );
      final end_ = arc.end;
      if (end_ != null) {
        // The dot comes in at the very end of the draw, the kit's 45-48%.
        final opacity = _window(progress, 0.45, 0.48);
        if (opacity > 0) {
          canvas.drawCircle(
            end_,
            7,
            Paint()..color = accentColor.withValues(alpha: opacity),
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ScrollRingsPainter oldDelegate) =>
      arcs != oldDelegate.arcs ||
      progressValue != oldDelegate.progressValue ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
}
