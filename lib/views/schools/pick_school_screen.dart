import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_dashed_border.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// 08 · Choose a school. Shown when someone is on the team at more than one
/// school and none was opened before (or they asked to switch).
class PickSchoolScreen extends StatelessWidget {
  const PickSchoolScreen({
    super.key,
    required this.schools,
    required this.email,
    required this.onPick,
    required this.onJoinAnother,
    required this.onSignOut,
  });

  final List<MemberSchool> schools;
  final String email;
  final ValueChanged<MemberSchool> onPick;
  final VoidCallback onJoinAnother;
  final VoidCallback onSignOut;

  /// Schools without a logo get a tile colour by position, so neighbours
  /// differ.
  static const _tones = [
    AppBadgeTone.info,
    AppBadgeTone.accent,
    AppBadgeTone.warning,
    AppBadgeTone.success,
  ];

  @override
  Widget build(BuildContext context) => AuthScreenFrame(
    showBackButton: false,
    scrollContent: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppText('Choose a school', variant: AppTextVariant.h1),
        const SizedBox(height: AppSpacing.ms),
        AppText(
          "You're on the team at ${schools.length} schools. We'll open this one next time, and you can switch any time from Home.",
          variant: AppTextVariant.bodyLarge,
          colorType: AppTextColor.textBody,
        ),
        const SizedBox(height: 28),
        for (final (index, school) in schools.indexed) ...[
          AppListRow(
            title: school.name,
            subtitle: school.rolesLabel,
            leading: switch (school.organization.logoUrl) {
              final String url when url.isNotEmpty => AppListLeading.network(
                url,
                name: school.name,
              ),
              _ => AppListLeading.icon(
                AppIcons.graduationCap,
                tone: _tones[index % _tones.length],
              ),
            },
            badge:
                school.isPaused
                    ? const AppBadge('Paused', tone: AppBadgeTone.warning)
                    : null,
            onTap: () => onPick(school),
          ),
          const SizedBox(height: AppSpacing.ms),
        ],
        _JoinAnotherSchool(onTap: onJoinAnother),
      ],
    ),
    footer: AuthAccountLine(
      email: email,
      actionLabel: 'Sign out',
      onTap: onSignOut,
    ),
  );
}

/// Dashed card at the end of the list that opens the join screen.
class _JoinAnotherSchool extends StatelessWidget {
  const _JoinAnotherSchool({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BouncyButton(
    onPressed: onTap,
    pressedScale: 0.98,
    child: AppDashedBorder(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppPalette.stone100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const AppIcon(
                AppIcons.plus,
                size: 22,
                color: AppPalette.stone700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Join another school',
                    variant: AppTextVariant.title,
                    colorType: AppTextColor.textStrong,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    'Have a new code? Add it here.',
                    style: AppTypography.body.copyWith(
                      color: AppPalette.stone600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
