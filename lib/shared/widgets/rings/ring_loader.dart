import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// An indeterminate loader drawn in the rings' language (the kits'
/// `ring-loader`): three arcs turning at their own pace — an outer and an
/// inner faint arc in the ring-art hairline with the accent arc between
/// them — round caps, each with its fixed gap.
///
/// The still picture is the same three arcs unrotated: reduced motion never
/// turns them. Pass [RingLoader.semanticsLabel] to announce it; otherwise it
/// announces the common "Loading" string.
class RingLoader extends StatefulWidget {
  const RingLoader({
    this.size = 24,
    this.color,
    this.trackColor,
    this.semanticsLabel,
    super.key,
  });

  /// Square side of the loader; the recipe's strokes scale with it.
  final double size;

  /// The accent (middle) arc's color; defaults to the theme's primary. Pass
  /// the surface's own text color on filled surfaces — the kit's `current`
  /// tone — e.g. inside a button.
  final Color? color;

  /// The two faint arcs' color; defaults to the brand's ring-art hairline.
  /// On a filled surface pass the text color at 40% for the faint arcs, the
  /// kit's `current` tone.
  final Color? trackColor;

  /// What the loader says, for screen readers.
  final String? semanticsLabel;

  @override
  State<RingLoader> createState() => _RingLoaderState();
}

class _RingLoaderState extends State<RingLoader> with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  final ValueNotifier<double> _elapsed = ValueNotifier<double>(0);

  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(RingLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  void _syncTicker() {
    if (_reducedMotion) {
      _ticker
        ?..stop()
        ..dispose();
      _ticker = null;
      if (_elapsed.value != 0) {
        _elapsed.value = 0;
      }
      return;
    }
    final ticker = _ticker ??= createTicker(_onTick);
    if (!ticker.isActive) {
      unawaited(ticker.start());
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      label: widget.semanticsLabel ?? context.t.common.loading,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: RingLoaderPainter(
            accentColor: widget.color ?? theme.colors.primary,
            lineColor: widget.trackColor ?? theme.brand.line,
            elapsed: _elapsed,
            // Under reduced motion the notifier never fires: still picture.
            repaint: _elapsed,
          ),
        ),
      ),
    );
  }
}

/// One arc of the loader recipe, in the 40x40 viewBox the web kit draws in.
///
/// The three arcs are fixed recipe values, so they live as enum members.
enum _LoaderArc {
  /// The outer faint arc: radius 18, dash `70 43.1`, one turn anticlockwise
  /// every 2.4s.
  outer(radius: 18, stroke: 2, sweepRadians: 70 / 18, seconds: 2.4, reverse: true),

  /// The accent arc: radius 12.5, dash `34 44.5`, clockwise every 1.1s.
  middle(radius: 12.5, stroke: 2.6, sweepRadians: 34 / 12.5, seconds: 1.1, reverse: false),

  /// The inner faint arc: radius 7, dash `30 14`, clockwise every 1.7s.
  inner(radius: 7, stroke: 2, sweepRadians: 30 / 7, seconds: 1.7, reverse: false);

  const _LoaderArc({
    required this.radius,
    required this.stroke,
    required this.sweepRadians,
    required this.seconds,
    required this.reverse,
  });

  final double radius;

  final double stroke;

  /// The drawn dash as a sweep in radians (arc length / radius).
  final double sweepRadians;

  final double seconds;

  final bool reverse;
}

/// Paints the loader: three arcs at their own pace, the middle one in the
/// accent. Each arc's dash starts at 3 o'clock and the whole arc rotates
/// around it; under reduced motion every arc holds its start.
class RingLoaderPainter extends CustomPainter {
  RingLoaderPainter({
    required this.accentColor,
    required this.lineColor,
    ValueListenable<double>? elapsed,
    super.repaint,
  }) : _elapsed = elapsed ?? const _FixedElapsed(0);

  final Color accentColor;

  final Color lineColor;

  final ValueListenable<double> _elapsed;

  static const List<_LoaderArc> _arcs = <_LoaderArc>[
    _LoaderArc.outer,
    _LoaderArc.middle,
    _LoaderArc.inner,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = _elapsed.value;
    // The recipe's viewBox is 40; every measure scales with the box.
    final scale = size.shortestSide / 40;
    final center = size.center(Offset.zero);
    for (final (index, arc) in _arcs.indexed) {
      final radius = arc.radius * scale;
      final rotation = arc.reverse ? -elapsed / arc.seconds : elapsed / arc.seconds;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        rotation * 2 * math.pi,
        arc.sweepRadians,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = arc.stroke * scale
          ..strokeCap = StrokeCap.round
          ..color = index == 1 ? accentColor : lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(RingLoaderPainter oldDelegate) =>
      accentColor != oldDelegate.accentColor || lineColor != oldDelegate.lineColor;
}

final class _FixedElapsed implements ValueListenable<double> {
  const _FixedElapsed(this.value);

  @override
  final double value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
