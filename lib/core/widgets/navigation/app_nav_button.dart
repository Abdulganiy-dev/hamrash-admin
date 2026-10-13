import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_metrics.dart';

/// Round floating button for the app bar: white circle, card border and
/// floating shadow. Scales down when pressed.
///
/// ```dart
/// AppNavIconButton(icon: LucideIcons.bell, count: 4, onPressed: openInbox)
/// AppNavIconButton(icon: LucideIcons.slidersHorizontal, showDot: hasFilters, onPressed: openFilters)
/// ```
class AppNavIconButton extends StatelessWidget {
  const AppNavIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.count,
    this.showDot = false,
    this.iconSize = 20,
    this.iconColor = AppPalette.slate700,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Red alert count on the top-right. Hidden when null or 0.
  final int? count;

  /// Small blue dot, e.g. when filters are applied. Ignored when [count]
  /// shows.
  final bool showDot;

  final double iconSize;
  final Color iconColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final showCount = count != null && count! > 0;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: BouncyButton(
        onPressed: onPressed,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: AppNavMetrics.buttonSize,
              height: AppNavMetrics.buttonSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.white,
                shape: BoxShape.circle,
                border: Border.all(color: LightColors.strokeColourStrokeCard),
                boxShadow: AppShadows.floating,
              ),
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
            if (showCount)
              Positioned(
                top: -4,
                right: -4,
                child: AppCountBadge(
                  count: count!,
                  tone: AppCountTone.alert,
                  outlineColor: AppPalette.white,
                ),
              )
            else if (showDot)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: LightColors.primaryPrimaryDefault,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Floating picture for the app bar: the user's avatar or the school logo.
/// Scales down when pressed if [onPressed] is set.
///
/// ```dart
/// AppNavPicture(
///   picture: AppListLeading.network(user.photoUrl, name: user.name),
///   onPressed: openProfile,
/// )
/// AppNavPicture.custom(child: SchoolLogo())
/// ```
class AppNavPicture extends StatelessWidget {
  const AppNavPicture({super.key, required this.picture, this.onPressed})
    : child = null;

  /// Any round content, clipped to a 44 circle (e.g. a logo).
  const AppNavPicture.custom({super.key, required this.child, this.onPressed})
    : picture = null;

  final AppListLeading? picture;
  final Widget? child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = picture != null
        ? AppLeadingPicture(leading: picture!, size: AppNavMetrics.buttonSize)
        : ClipOval(
            child: SizedBox.square(
              dimension: AppNavMetrics.buttonSize,
              child: child,
            ),
          );

    return BouncyButton(
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppShadows.floating,
        ),
        child: content,
      ),
    );
  }
}
