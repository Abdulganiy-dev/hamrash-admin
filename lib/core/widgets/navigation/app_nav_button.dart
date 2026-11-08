import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_metrics.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// Round floating button for the app bar: white circle, card border and
/// floating shadow. Scales down when pressed.
///
/// ```dart
/// AppNavIconButton(icon: AppIcons.bell, count: 4, onPressed: openInbox)
/// AppNavIconButton(icon: AppIcons.slidersHorizontal, appliedCount: 3, ...)
/// ```
class AppNavIconButton extends StatelessWidget {
  const AppNavIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.count,
    this.showDot = false,
    this.appliedCount = 0,
    this.iconSize = 20,
    this.iconColor = AppPalette.stone700,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Red alert count on the top-right. Hidden when null or 0.
  final int? count;

  /// Small aubergine dot, e.g. when filters are applied. Ignored when [count]
  /// shows.
  final bool showDot;

  /// A filter button with filters applied: when above 0 the button turns
  /// light aubergine and an aubergine count badge sits on its top-right.
  /// Takes the place of [count] and [showDot].
  final int appliedCount;

  final double iconSize;
  final Color iconColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final applied = appliedCount > 0;
    final showCount = !applied && count != null && count! > 0;

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
                color: applied
                    ? LightColors.primaryPrimaryMute
                    : AppPalette.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: applied
                      ? LightColors.primaryPrimaryThin
                      : LightColors.strokeColourStrokeCard,
                ),
                boxShadow: AppShadows.floating,
              ),
              child: AppIcon(icon, size: iconSize, color: iconColor),
            ),
            if (applied)
              Positioned(
                top: -6,
                right: -6,
                child: _AppliedBadge(count: appliedCount),
              )
            else if (showCount)
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

/// The aubergine count on a filter button: 18 tall, white 2px ring.
class _AppliedBadge extends StatelessWidget {
  const _AppliedBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 18),
    height: 18,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: LightColors.primaryPrimaryDefault,
      borderRadius: AppRadius.brBadge,
      border: Border.all(color: AppPalette.white, width: 2),
    ),
    child: AppText(
      count > 99 ? '99+' : '$count',
      style: AppTypography.overline.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 14 / 11,
        color: AppPalette.white,
      ),
    ),
  );
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
    final content =
        picture != null
            ? AppLeadingPicture(
              leading: picture!,
              size: AppNavMetrics.buttonSize,
            )
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
