import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';

/// Fades scrolled content out at the top edge of [child], so rows dissolve
/// under a header instead of being cut off by a hard line. The fade only
/// shows once the content has scrolled; at rest the top stays crisp.
///
/// Wrap the scroll view itself (not a parent with other fixed content), and
/// match [color] to the surface behind it.
///
/// ```dart
/// AppScrollFade(child: ListView(...))
/// ```
class AppScrollFade extends StatefulWidget {
  const AppScrollFade({
    super.key,
    required this.child,
    this.color = AppPalette.white,
    this.extent = 24,
  });

  final Widget child;

  /// The surface colour the content fades into.
  final Color color;

  /// How tall the fade is.
  final double extent;

  @override
  State<AppScrollFade> createState() => _AppScrollFadeState();
}

class _AppScrollFadeState extends State<AppScrollFade> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    // Only the scroll view directly inside, not nested ones.
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final scrolled =
          notification.metrics.pixels > notification.metrics.minScrollExtent;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: widget.extent,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _scrolled ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [widget.color, widget.color.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
