import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_status_badge.dart';

/// 9.20 · One section on the sections list: its name, how far its grading has
/// got, a one-line summary, and whether it follows the school's setup.
class GradingSectionRow extends StatelessWidget {
  const GradingSectionRow({
    super.key,
    required this.grading,
    required this.onTap,
  });

  final SectionGrading grading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          grading.sectionName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.subtitle.copyWith(
                            fontSize: 15,
                            color: LightColors.textStrong,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      gradingStatusBadge(grading.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    grading.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: LightColors.textMuted,
                    ),
                  ),
                  if (grading.usesSchoolSetup) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const AppIcon(
                          AppIcons.house,
                          size: 14,
                          color: LightColors.primaryPrimaryText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AppText(
                            'Uses the school’s setup',
                            style: AppTypography.body.copyWith(
                              fontSize: 13,
                              height: 18 / 13,
                              fontWeight: FontWeight.w700,
                              color: LightColors.primaryPrimaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (onTap != null)
              const AppIcon(
                AppIcons.chevronRight,
                size: 18,
                color: AppPalette.stone400,
              ),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return BouncyButton(pressedScale: 0.98, onPressed: onTap, child: content);
  }
}
