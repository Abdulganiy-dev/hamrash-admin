import 'package:hamrash_admin/core/widgets/blur_transition.dart';
import 'package:flutter/material.dart';

/// Swaps a dashboard section's content (shimmer ↔ error ↔ empty ↔ data) with a
/// blur-and-fade transition, while smoothly animating the surrounding card's
/// height between states.
///
/// The [child] must carry a [Key] that changes whenever the visual state
/// changes (e.g. `ValueKey('loading')`, `ValueKey('data:3')`) — that key change
/// is what drives the [AnimatedSwitcher] to cross-transition the old and new
/// content via [BlurTransition].
class AnimatedSectionContent extends StatelessWidget {
  const AnimatedSectionContent({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
    this.maxBlur = 5,
    this.addTransitionBuilder = true,
  });

  /// The current content. Give it a state-dependent [Key] (see class docs).
  final Widget child;

  /// Duration of both the blur/fade switch and the height morph.
  final Duration duration;

  /// Peak blur sigma for the outgoing/incoming content.
  final double maxBlur;

  final bool addTransitionBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        transitionBuilder: addTransitionBuilder
            ? BlurTransition.builder(maxBlur: maxBlur)
            : AnimatedSwitcher.defaultTransitionBuilder,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [...previousChildren, ?currentChild],
        ),
        child: child,
      ),
    );
  }
}
