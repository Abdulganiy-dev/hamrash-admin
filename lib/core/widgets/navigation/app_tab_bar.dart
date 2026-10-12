import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
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

  final String label;

  /// Red alert count on the icon. Hidden when null or 0.
  final int? count;
}

/// Floating capsule tab bar. The selected tab turns blue and bold; there is
/// no fill behind it. Usually built for you by [AppTabShell].
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
    return Container(
      height: AppNavMetrics.tabBarHeight,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: LightColors.strokeColourStrokeSoft),
        boxShadow: AppShadows.floating,
      ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: _duration,
                  builder: (context, value, _) => Icon(
                    selected ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 22,
                    color: value,
                  ),
                ),
                if (showCount)
                  Positioned(
                    left: 11,
                    top: -5,
                    child: AppCountBadge(
                      count: item.count!,
                      tone: AppCountTone.alert,
                      outlineColor: AppPalette.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: _duration,
              style: AppTypography.label.copyWith(
                fontSize: 11,
                height: 14 / 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
