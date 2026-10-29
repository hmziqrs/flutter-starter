import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// The brand wordmark's shimmer move: a band of the shine color sweeps across
/// the letters once per cycle, then rests (`logo.ts` textMove "shimmer").
///
/// Wrap any letters — an `AppWordmark`, a heading, a logo lockup. The sweep
/// runs for [duration], then the band rests off-canvas for [rest]. Under
/// reduced motion the highlight never appears and the child renders as-is;
/// nothing here reacts to hover, press or focus.
class BrandShimmer extends StatefulWidget {
  const BrandShimmer({
    required this.child,
    this.shine,
    this.shineWidth = 0.25,
    this.duration = const Duration(milliseconds: 1600),
    this.rest = const Duration(milliseconds: 3000),
    this.once = false,
    super.key,
  });

  /// The child whose letters catch the highlight.
  final Widget child;

  /// The highlight color; defaults to the theme's mark square (bright orange,
  /// the web kit's default shine).
  final Color? shine;

  /// How wide the band is, as a share of the child's width.
  final double shineWidth;

  /// How long one sweep takes.
  final Duration duration;

  /// How long the letters rest before the next sweep.
  final Duration rest;

  /// Play one sweep and stop instead of cycling.
  final bool once;

  @override
  State<BrandShimmer> createState() => _BrandShimmerState();
}

class _BrandShimmerState extends State<BrandShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _clock.duration = widget.duration + widget.rest;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(BrandShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _clock.duration = widget.duration + widget.rest;
    _syncClock();
  }

  void _syncClock() {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_clock.isAnimating) {
        _clock.stop();
      }
      return;
    }
    if (widget.once) {
      if (!_clock.isAnimating && _clock.value == 0) {
        unawaited(_clock.forward());
      }
    } else if (!_clock.isAnimating) {
      unawaited(_clock.repeat());
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    final shine = widget.shine ?? context.theme.brand.markSquare;
    final moveShare = widget.duration.inMicroseconds / _clock.duration!.inMicroseconds;
    final half = widget.shineWidth.clamp(0.02, 1) / 2;
    return AnimatedBuilder(
      animation: _clock,
      child: widget.child,
      builder: (context, child) {
        // The band enters from the left edge and exits right, like the CSS
        // background-position sweep from 100% to 0% across a 300%-wide image.
        final progress = (_clock.value / moveShare).clamp(0.0, 1.0);
        final center = -0.5 + 2 * progress;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final clear = shine.withAlpha(0);
            final start = (center - half).clamp(0.0, 1.0);
            final end = (center + half).clamp(0.0, 1.0);
            if (end - start <= 0) {
              return LinearGradient(colors: <Color>[clear, clear]).createShader(bounds);
            }
            return LinearGradient(
              colors: <Color>[clear, shine, clear],
              stops: <double>[start, center.clamp(start, end), end],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
