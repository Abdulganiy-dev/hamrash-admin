import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

import 'package:hamrash_admin/core/constants/app_colors.dart';
import '../app_badge.dart';
import '../app_svg_icon.dart';
import '../button/bouncy_button.dart';
import 'app_nav_metrics.dart';

/// One tab in an [AppTabBar].
class AppTabItem {
  const AppTabItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.count,
  });

  /// The bundled SVG icon for this tab.
  final AppSvgIconData icon;

  /// Optional heavier SVG for the selected tab.
  final AppSvgIconData? activeIcon;

  /// Not shown; read out by screen readers.
  final String label;

  /// Red alert count on the icon. Hidden when null or 0.
  final int? count;
}

/// Icon-only tabs grouped in the centre of the page-colour bar, with no
/// background, border or shadow. The selected tab uses the active tint with a heavier
/// stroke and a shared dot that slides between tabs on a spring; the icon
/// pops in on a spring and the others are muted. Usually built for you by
/// [AppTabShell].
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar>
    with SingleTickerProviderStateMixin {
  double _initialPosition() => widget.items.isEmpty
      ? 0
      : widget.currentIndex.clamp(0, widget.items.length - 1).toDouble();

  late final SingleMotionController _position = SingleMotionController(
    motion: const Motion.smoothSpring(),
    vsync: this,
    initialValue: _initialPosition(),
  );

  @override
  void didUpdateWidget(AppTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _initialPosition();
    if (oldWidget.items.length != widget.items.length) {
      _position.value = _position.value
          .clamp(
            0,
            widget.items.isEmpty ? 0.0 : (widget.items.length - 1).toDouble(),
          )
          .toDouble();
    }
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.items.length != widget.items.length) {
      _position.animateTo(target);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = dark
        ? DarkColors.primaryPrimaryText
        : LightColors.primaryPrimaryText;
    // Reserve a dot row so the icon stays still while the dot slides.
    const iconSize = 22.0;
    const gap = 5.0;
    const dotSize = 5.0;
    final dotTop =
        (AppNavMetrics.tabBarHeight - iconSize - gap - dotSize) / 2 +
        iconSize +
        gap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = widget.items.isEmpty
            ? AppNavMetrics.tabWidth
            : (constraints.maxWidth / widget.items.length)
                  .clamp(0.0, AppNavMetrics.tabWidth)
                  .toDouble();
        return SizedBox(
          height: AppNavMetrics.tabBarHeight,
          child: Center(
            child: SizedBox(
              width: widget.items.length * tabWidth,
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        SizedBox(
                          width: tabWidth,
                          child: _Tab(
                            item: widget.items[i],
                            selected: i == widget.currentIndex,
                            onTap: () => widget.onTap(i),
                          ),
                        ),
                    ],
                  ),
                  if (widget.items.isNotEmpty)
                    AnimatedBuilder(
                      animation: _position,
                      builder: (context, _) => PositionedDirectional(
                        start:
                            _position.value * tabWidth +
                            tabWidth / 2 -
                            dotSize / 2,
                        top: dotTop,
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: SizedBox.square(
                              dimension: dotSize,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: active,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final AppTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with SingleTickerProviderStateMixin {
  static const _colorDuration = Duration(milliseconds: 160);

  /// How small the icon starts when it becomes active, before springing back
  /// past full size and settling.
  static const double _popFrom = 0.82;

  /// 1 when active; drives the icon pop.
  late final SingleMotionController _active = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
    initialValue: widget.selected ? 1 : 0,
  );

  @override
  void didUpdateWidget(_Tab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    if (widget.selected) {
      // Pop: start a little small and spring up with some overshoot.
      _active.animateTo(1, from: _popFrom);
    } else {
      _active.animateTo(0);
    }
  }

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = widget.selected;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // The icon and shared dot use the same active tint.
    final active = dark
        ? DarkColors.primaryPrimaryText
        : LightColors.primaryPrimaryText;
    final idle = dark ? DarkColors.textMuted : LightColors.textMuted;
    final color = selected ? active : idle;
    final showCount = item.count != null && item.count! > 0;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: widget.onTap,
        child: AnimatedBuilder(
          animation: _active,
          builder: (context, _) {
            final t = _active.value;
            // Only the active tab pops; an idle one stays at full size.
            final iconScale = selected ? t.clamp(0.0, 1.3) : 1.0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: iconScale,
                  child: SizedBox.square(
                    dimension: 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TweenAnimationBuilder<Color?>(
                          tween: ColorTween(end: color),
                          duration: _colorDuration,
                          builder: (context, value, _) => AppSvgIcon(
                            selected
                                ? (item.activeIcon ?? item.icon)
                                : item.icon,
                            size: 22,
                            color: value,
                          ),
                        ),
                        if (showCount)
                          Positioned(
                            left: 14,
                            top: -6,
                            child: AppCountBadge(
                              count: item.count!,
                              tone: AppCountTone.alert,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const SizedBox(height: 5),
              ],
            );
          },
        ),
      ),
    );
  }
}
