import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/schools/widgets/school_logo.dart';

/// The school at the top of the More tab: logo, name and code, with a
/// Switch pill for people in more than one school.
class MoreSchoolCard extends StatelessWidget {
  const MoreSchoolCard({
    super.key,
    required this.school,
    required this.onTap,
    this.onSwitch,
  });

  final MemberSchool school;
  final VoidCallback onTap;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        SchoolLogo(logoUrl: school.organization.logoUrl, size: 48, radius: 14),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                school.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.heading(
                  17,
                  lineHeight: 22,
                ).copyWith(color: AppPalette.stone900),
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppText(
                school.organization.code,
                variant: AppTextVariant.body,
                colorType: AppTextColor.textMuted,
              ),
            ],
          ),
        ),
        if (onSwitch != null) ...[
          const SizedBox(width: AppSpacing.sm),
          BouncyButton(
            onPressed: onSwitch,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.stone100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const AppText(
                'Switch',
                variant: AppTextVariant.label,
                colorType: AppTextColor.textStrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
