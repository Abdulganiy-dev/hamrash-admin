import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:flutter/material.dart';

/// Outer surface card used as a grouping container for inner content.
///
/// Uses the muted surface color from the theme and [AppRadius.xlLg] rounding
/// by default. Pair it with [AppElevatedCard] children for the stacked
/// "card on card" look used on the home dashboard.
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final resolvedColor =
        color ??
        (isLight
            ? LightColors.backgroundSurfaceMute
            : DarkColors.backgroundSurfaceMute);

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xl),
      ),
      child: child,
    );
  }
}

/// Elevated inner card with a soft shadow, intended to sit inside an
/// [AppSurfaceCard] or directly on the scaffold background.
///
/// The card color and shadow color adapt to the current theme's brightness
/// automatically, so the same widget looks correct in light and dark mode.
class AppElevatedCard extends StatelessWidget {
  const AppElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.cardColor,
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? cardColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final resolvedCardColor =
        cardColor ??
        (isLight ? Colors.white : DarkColors.backgroundSurfaceLayer);
    final resolvedShadowColor =
        shadowColor ??
        (isLight
            ? Colors.black.withOpacity(0.06)
            : Colors.black.withOpacity(0.35));

    return Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: resolvedCardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: resolvedShadowColor,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: resolvedShadowColor,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
