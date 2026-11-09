import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';

/// 11.13 · Registered: where they are, their admission number, the main
/// contact and how many parents were linked.
class RegisteredView extends StatelessWidget {
  const RegisteredView({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final student = model.registered!;
    final parents = student.parentIds.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xxl,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LightColors.successSuccessMute,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const AppIcon(
                AppIcons.check,
                size: 30,
                color: LightColors.successSuccessDefault,
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppText(
            '${student.firstName} is registered',
            style: AppTypography.h1.copyWith(
              fontWeight: FontWeight.w800,
              color: LightColors.textStrong,
            ),
          ),
          const SizedBox(height: 14),
          AppText(
            model.registeredSummary,
            style: AppTypography.bodyLarge.copyWith(
              color: LightColors.textBody,
            ),
          ),
          const SizedBox(height: 28),
          AppCard(
            padding: AppSectionCard.cardPadding,
            child: Column(
              children: [
                _Fact(
                  label: 'Admission number',
                  value: student.admissionNumber,
                ),
                const AppDivider(indent: 0, endIndent: 0),
                _Fact(
                  label: 'Main contact',
                  value: model.mainContact?.displayName ?? '',
                ),
                const AppDivider(indent: 0, endIndent: 0),
                _Fact(
                  label: 'Parents',
                  value: parents == 1 ? '1 linked' : '$parents linked',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        AppText(
          label,
          style: AppTypography.body.copyWith(color: LightColors.textMuted),
        ),
        const SizedBox(width: AppSpacing.ms),
        Expanded(
          child: AppText(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.subtitle.copyWith(
              color: LightColors.textStrong,
            ),
          ),
        ),
      ],
    ),
  );
}
