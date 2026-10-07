import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Animates a Gaussian blur driven by an [Animation], the blur analogue of
/// [FadeTransition].
///
/// The child is sharpest at `animation.value == 1.0` (sigma `0`) and most
/// blurred at `0.0` (sigma [maxBlur]). Because an [AnimatedSwitcher] drives
/// the incoming child forward (0→1) and the outgoing child in reverse
/// (1→0), the same builder makes the new child resolve *into* focus while
/// the old one dissolves *out* of focus — exactly mirroring how a
/// [FadeTransition] cross-fades.
///
/// Drop-in usage inside an [AnimatedSwitcher]:
/// ```dart
/// AnimatedSwitcher(
///   duration: const Duration(milliseconds: 260),
///   transitionBuilder: (child, animation) =>
///       BlurTransition(animation: animation, child: child),
///   child: ...,
/// )
/// ```
///
/// Or use the [BlurTransition.builder] helper to pass straight to
/// `transitionBuilder` while tuning [maxBlur] / [fade]:
/// ```dart
/// AnimatedSwitcher(
///   duration: const Duration(milliseconds: 260),
///   transitionBuilder: BlurTransition.builder(maxBlur: 16),
///   child: ...,
/// )
/// ```
class BlurTransition extends AnimatedWidget {
  const BlurTransition({
    super.key,
    required Animation<double> animation,
    this.maxBlur = 12.0,
    this.fade = true,
    this.child,
  }) : super(listenable: animation);

  /// The blur sigma applied when the animation sits at `0.0`. Interpolates
  /// linearly to `0` as the animation reaches `1.0`.
  final double maxBlur;

  /// Whether to also cross-fade opacity alongside the blur. Recommended for
  /// [AnimatedSwitcher], where both children are stacked during the
  /// transition — without a fade the two fully-opaque layers overlap.
  final bool fade;

  final Widget? child;

  Animation<double> get animation => listenable as Animation<double>;

  /// Convenience for `AnimatedSwitcher.transitionBuilder`. Returns a builder
  /// closure so you can configure [maxBlur] / [fade] inline.
  static AnimatedSwitcherTransitionBuilder builder({
    double maxBlur = 12.0,
    bool fade = true,
  }) {
    return (Widget child, Animation<double> animation) => BlurTransition(
          animation: animation,
          maxBlur: maxBlur,
          fade: fade,
          child: child,
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = animation.value.clamp(0.0, 1.0);
    final sigma = (1.0 - t) * maxBlur;

    Widget result = ImageFiltered(
      // Skip the (expensive) filter entirely once the child is effectively
      // sharp — also avoids a saveLayer when the switcher is idle at t == 1.
      enabled: sigma > 0.01,
      imageFilter: ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        // decal keeps edges transparent instead of smearing clamped pixels.
        tileMode: TileMode.decal,
      ),
      child: child,
    );

    if (fade) {
      result = Opacity(opacity: t, child: result);
    }

    return result;
  }
}
