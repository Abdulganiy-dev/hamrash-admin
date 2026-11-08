import 'package:hamrash_admin/core/widgets/blur_transition.dart';
import 'package:flutter/material.dart';

/// Swaps a section's content (shimmer ↔ error ↔ empty ↔ data) with a
/// blur-and-fade transition, and — unless [morphHeight] is false — animates the
/// surrounding height between states too.
///
/// The [child] must carry a [Key] that changes whenever the visual state
/// changes (e.g. `ValueKey('loading')`, `ValueKey('data:3')`) — that key change
/// is what drives the [AnimatedSwitcher] to cross-transition the old and new
/// content via [BlurTransition].
///
/// Set [morphHeight] to false for a full-page body: there is nothing to morph
/// (the page is already the height of the screen) and an [AnimatedSize] around
/// a scroll viewport fights its own measurement.
class AnimatedSectionContent extends StatelessWidget {
  const AnimatedSectionContent({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
    this.maxBlur = 5,
    this.morphHeight = true,
    this.addTransitionBuilder = true,
  });

  /// The current content. Give it a state-dependent [Key] (see class docs).
  final Widget child;

  /// Duration of both the blur/fade switch and the height morph.
  final Duration duration;

  /// Peak blur sigma for the outgoing/incoming content.
  final double maxBlur;

  /// Whether to animate the height between states. False for a full-page body.
  final bool morphHeight;

  final bool addTransitionBuilder;

  @override
  Widget build(BuildContext context) {
    // Reduced motion keeps the crossfade (it is what explains the change) and
    // drops the blur and most of its length.
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? const Duration(milliseconds: 120)
        : this.duration;

    final switcher = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: addTransitionBuilder
          ? BlurTransition.builder(maxBlur: reduced ? 0 : maxBlur)
          : AnimatedSwitcher.defaultTransitionBuilder,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          for (final previous in previousChildren)
            ExcludeSemantics(child: IgnorePointer(child: previous)),
          ?currentChild,
        ],
      ),
      child: child,
    );

    if (!morphHeight) return switcher;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: switcher,
    );
  }
}
