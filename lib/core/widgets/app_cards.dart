import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_surface.dart';

/// Elevation shadows. Light mode only — dark surfaces separate by color, so
/// dark cards get an edge instead of a shadow.
class AppShadows {
  AppShadows._();

  /// Cards on the page: a tight contact shadow plus a soft blue-slate float
  /// pooled under the card. Paired with the 1px slate border on [AppCard].
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x080F172A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x1A25488C),
      offset: Offset(0, 14),
      blurRadius: 27,
      spreadRadius: -10,
    ),
  ];

  /// Menus, sheets and dialogs that sit above everything.
  static const List<BoxShadow> overlay = [
    BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color(0x140F172A), offset: Offset(0, 12), blurRadius: 20),
    BoxShadow(
      color: Color(0x330F172A),
      offset: Offset(0, 32),
      blurRadius: 52,
      spreadRadius: -16,
    ),
  ];
}

/// White card that floats on the page canvas.
///
/// Holds content only: put a section title above it with [AppSectionHeader]
/// and any action button below it, outside the card.
///
/// ```dart
/// AppSectionHeader(title: 'Your classes', actionLabel: 'See all', onAction: _openClasses),
/// const SizedBox(height: AppSpacing.ms),
/// AppCard(child: ...),
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.enableHaptic = true,
  });

  final Widget child;

  /// Defaults to 20 on all sides. Use [EdgeInsets.zero] for list cards whose
  /// rows carry their own padding.
  final EdgeInsetsGeometry padding;

  /// Makes the whole card tappable; it scales to 98% while pressed.
  final VoidCallback? onTap;

  final bool enableHaptic;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isLight ? AppPalette.white : DarkColors.backgroundSurfaceLayer,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: isLight
              ? LightColors.strokeColourStrokeSoft
              : const Color(0x0FFFFFFF),
        ),
        boxShadow: isLight ? AppShadows.floating : null,
      ),
      // Inputs inside a card switch to the slate-50 fill.
      child: AppSurfaceScope(surface: AppSurface.card, child: child),
    );

    if (onTap == null) return card;
    return BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      enableHaptic: enableHaptic,
      child: card,
    );
  }
}

/// Box nested inside an [AppCard]: soft fill, hairline border, no shadow.
class AppFlatCard extends StatelessWidget {
  const AppFlatCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.ms,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isLight ? AppPalette.slate50 : DarkColors.backgroundSurfaceMute,
        borderRadius: AppRadius.brControl,
        border: Border.all(
          color: isLight ? AppPalette.slate200 : AppPalette.slate700,
        ),
      ),
      child: child,
    );
  }
}

/// Title (and optional link) that sits above a card, outside it.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  }) : assert(
         trailing == null || actionLabel == null,
         'Provide either trailing or actionLabel, not both.',
       );

  final String title;

  /// Text link on the right, e.g. "See all".
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Custom widget on the right instead of a text link.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Widget? end = trailing;
    if (actionLabel != null) {
      end = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: AppText(
            actionLabel!,
            variant: AppTextVariant.subtitle,
            colorType: AppTextColor.textBrand,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: AppText(title, variant: AppTextVariant.title)),
          ?end,
        ],
      ),
    );
  }
}
