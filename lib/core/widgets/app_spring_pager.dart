import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

/// Pages laid side by side, one width apart, sliding to [index] on a motor
/// spring. Used by the onboarding steps and the tab shell.
///
/// Every page moves from one spring value, so a leaving page and an arriving
/// one can never overlap. Pages stay built (they keep typed text, scroll
/// position, and so on); a page that is fully off screen doesn't paint, take
/// taps or focus, or run animations.
///
/// A jump of more than one page (tab 1 → tab 3) slides like a move to the
/// next page: the page being left is drawn right beside the target and the
/// pages in between stay hidden, so it never sweeps past them (which may not
/// even be built yet, see `AppTabShell`).
class AppSpringPager extends StatefulWidget {
  const AppSpringPager({
    super.key,
    required this.index,
    required this.children,
    this.motion = const Motion.snappySpring(),
  });

  /// The page to show.
  final int index;
  final List<Widget> children;
  final Motion motion;

  @override
  State<AppSpringPager> createState() => _AppSpringPagerState();
}

class _AppSpringPagerState extends State<AppSpringPager>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _position = SingleMotionController(
    motion: widget.motion,
    vsync: this,
    initialValue: widget.index.toDouble(),
  );

  /// During a long jump: the page being left, and the slot it's drawn in
  /// (beside the target). Null for ordinary moves.
  int? _leaving;
  double? _leavingSlot;

  @override
  void didUpdateWidget(AppSpringPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) _position.motion = widget.motion;
    if (oldWidget.index == widget.index) return;

    final from = oldWidget.index;
    final to = widget.index;
    if ((to - from).abs() > 1) {
      final side = to > from ? -1.0 : 1.0;
      _leaving = from;
      _leavingSlot = to + side;
      // Where the old page now "is": one page from the target, plus any
      // distance it still had to settle.
      final start = to + side + (_position.value - from);
      _position.animateTo(to.toDouble(), from: start).whenComplete(_endJump);
    } else {
      _endJump();
      _position.animateTo(to.toDouble());
    }
  }

  void _endJump() {
    if (_leaving == null) return;
    if (!mounted) return;
    setState(() {
      _leaving = null;
      _leavingSlot = null;
    });
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _position,
            builder: (context, _) => Stack(
              children: [
                for (var i = 0; i < widget.children.length; i++)
                  _page(i, _position.value, width),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _page(int i, double position, double width) {
    final leaving = _leaving;
    final double slot;
    if (leaving == null || i == widget.index) {
      slot = i.toDouble();
    } else if (i == leaving) {
      slot = _leavingSlot!;
    } else {
      // A page between the two ends of a long jump: keep it out of sight.
      slot = double.infinity;
    }

    final distance = slot - position;
    final away = !distance.isFinite || distance.abs() >= 0.999;
    return Positioned.fill(
      // Keyed by position so a page keeps its state while others move.
      key: ValueKey(i),
      child: Offstage(
        offstage: away,
        child: TickerMode(
          enabled: !away,
          child: IgnorePointer(
            // Only the page being settled on takes taps.
            ignoring: i != widget.index,
            child: Transform.translate(
              offset: Offset(distance.isFinite ? distance * width : 0, 0),
              child: widget.children[i],
            ),
          ),
        ),
      ),
    );
  }
}
