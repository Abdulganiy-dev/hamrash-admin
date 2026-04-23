import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:motor/motor.dart';

/// A single tab definition for [HamrashTabBar].
///
/// [icon] renders in the default (inactive) state. [activeIcon], if provided,
/// renders when this tab is the current index; otherwise [icon] is reused and
/// the bar colours it with [HamrashTabBar.activeIconColor] via an
/// [IconTheme] override.
class HamrashTabItem {
  const HamrashTabItem({required this.icon, this.activeIcon});

  final Widget icon;
  final Widget? activeIcon;
}

/// Black, top-rounded bottom tab bar that sits flush with the bottom edge.
///
/// Each tab scales down to 0.95 on press with a snappy spring (same motion
/// used by [AppButton]) and fires a light haptic tick on tap.
class HamrashTabBar extends StatelessWidget {
  const HamrashTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = 60,
    this.topPadding = 18,
    this.topRadius = 40,
    this.backgroundColor,
    this.activeIconColor,
    this.inactiveIconColor,
  }) : assert(items.length >= 2, 'HamrashTabBar needs at least 2 items.');

  final List<HamrashTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Height of the row of tab icons (excluding top padding and bottom safe-area inset).
  final double height;

  /// Extra breathing room above the icon row, below the rounded top.
  final double topPadding;

  /// Corner radius of the top-left/top-right corners.
  final double topRadius;

  final Color? backgroundColor;
  final Color? activeIconColor;
  final Color? inactiveIconColor;

  @override
  Widget build(BuildContext context) {
    
    Color _bottomSectionColor(BuildContext context) {
      final isLight = Theme.of(context).brightness == Brightness.light;
      return isLight ? Colors.black : DarkColors.primaryNeutralBlack;
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final activeColor = activeIconColor ?? LightColors.primaryOncolorWhite;
    final inactiveColor =
        inactiveIconColor ??
        LightColors.primaryOncolorWhite.withValues(alpha: 0.55);

    return Container(
      decoration: BoxDecoration(
        color: _bottomSectionColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      padding: EdgeInsets.only(top: topPadding, bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isActive = index == currentIndex;
            return Expanded(
              child: _HamrashTabItemView(
                item: items[index],
                isActive: isActive,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Internal tap target for a single tab that mirrors [AppButton]'s press-to-
/// scale animation (snappy spring toward 0.95 on press, toward 1.0 on release).
class _HamrashTabItemView extends StatefulWidget {
  const _HamrashTabItemView({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final HamrashTabItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  State<_HamrashTabItemView> createState() => _HamrashTabItemViewState();
}

class _HamrashTabItemViewState extends State<_HamrashTabItemView> {
  double _scaleTarget = 1.0;

  static const double _pressedScale = 0.95;
  static const Motion _scaleMotion = Motion.snappySpring();

  void _handlePressDown() {
    setState(() => _scaleTarget = _pressedScale);
  }

  void _handlePressUp() {
    setState(() => _scaleTarget = 1.0);
  }

  void _handlePressCancel() {
    setState(() => _scaleTarget = 1.0);
  }

  void _handleTap() {
    HapticHelpers.vibrate(VibrationType.light);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? widget.activeColor : widget.inactiveColor;
    final glyph = widget.isActive
        ? (widget.item.activeIcon ?? widget.item.icon)
        : widget.item.icon;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handlePressDown(),
      onTapUp: (_) {
        _handlePressUp();
        _handleTap();
      },
      onTapCancel: _handlePressCancel,
      child: SingleMotionBuilder(
        motion: _scaleMotion,
        value: _scaleTarget,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(color: color, size: 24),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: color),
              child: glyph,
            ),
          ),
        ),
      ),
    );
  }
}
