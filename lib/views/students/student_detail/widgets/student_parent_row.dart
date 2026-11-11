import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// A 68 row for the Parents card: a 40 initials circle, the name over
/// "Mother · Primary contact" (or their number), and a chevron when the row
/// opens the parent's actions.
class StudentParentRow extends StatelessWidget {
  const StudentParentRow({
    super.key,
    required this.parent,
    required this.caption,
    required this.tint,
    this.onTap,
  });

  final StudentParent parent;
  final String caption;
  final ({Color fill, Color foreground}) tint;
  final VoidCallback? onTap;

  static const double rowHeight = 68;

  /// The category tints a parent's circle cycles through, picked from their
  /// position so a parent keeps theirs between loads.
  static const tints = [
    (
      fill: LightColors.categoryTangerineMute,
      foreground: LightColors.categoryTangerineText,
    ),
    (
      fill: LightColors.categoryTealMute,
      foreground: LightColors.categoryTealText,
    ),
    (
      fill: LightColors.categoryHoneyMute,
      foreground: LightColors.categoryHoneyText,
    ),
    (
      fill: LightColors.categoryChartreuseMute,
      foreground: LightColors.categoryChartreuseText,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final body = SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint.fill, shape: BoxShape.circle),
            child: AppText(
              parent.initials,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                color: tint.foreground,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  parent.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w700,
                    color: LightColors.textStrong,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                AppText(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: AppIcon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: AppPalette.stone400,
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return body;
    return Semantics(
      button: true,
      label: '${parent.displayName}. $caption',
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: onTap,
        pressedScale: 0.98,
        child: ColoredBox(color: Colors.transparent, child: body),
      ),
    );
  }
}
