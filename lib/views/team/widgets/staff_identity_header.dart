import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/views/team/widgets/staff_status_pill.dart';

/// The top of a staff member's page: large initials, name, the role and app
/// (or when they joined), and their status pill.
class StaffIdentityHeader extends StatelessWidget {
  const StaffIdentityHeader({
    super.key,
    required this.member,
    required this.subtitle,
    required this.access,
  });

  final StaffMember member;
  final String subtitle;
  final StaffAccess access;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppLeadingPicture(
        leading: AppListLeading.initials(
          member.fullName,
          pending: access == StaffAccess.invitePending,
        ),
        size: 72,
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              member.fullName,
              style: AppTypography.h2.copyWith(color: LightColors.textStrong),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppText(
              subtitle,
              variant: AppTextVariant.body,
              colorType: AppTextColor.textBody,
            ),
            const SizedBox(height: AppSpacing.stack),
            StaffStatusPill(access: access, detail: true),
          ],
        ),
      ),
    ],
  );
}
