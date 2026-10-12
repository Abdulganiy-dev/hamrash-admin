import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_metrics.dart';

/// One tab in an [AppTabBar].
class AppTabItem {
  const AppTabItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.count,
  });

  final IconData icon;

  /// Heavier icon for the selected tab, e.g. `LucideIcons.house500`.
  /// Falls back to [icon].
  final IconData? activeIcon;

  /// Not shown; read out by screen readers.
  final String label;

  /// Red alert count on the icon. Hidden when null or 0.
  final int? count;
}

/// Plain icon-only tab bar that sits on the page colour, with no
/// background, border or shadow. The selected icon turns blue and heavier.
/// Usually built for you by [AppTabShell], which also fades content out
/// behind it.
class AppTabBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppNavMetrics.tabBarHeight,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _Tab(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final AppTabItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? LightColors.primaryPrimaryText
        : AppPalette.slate500;
    final showCount = item.count != null && item.count! > 0;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: onTap,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: _duration,
                builder: (context, value, _) => Icon(
                  selected ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 24,
                  color: value,
                ),
              ),
              if (showCount)
                Positioned(
                  left: 12,
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
    );
  }
}
