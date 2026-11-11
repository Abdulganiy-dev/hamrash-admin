import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// The top of the student page, centred: an 80 circle (their photo, or
/// initials), the name, "JSS 1B · KCL/2026/0021" and the status pill.
class StudentHero extends StatelessWidget {
  const StudentHero({
    super.key,
    required this.student,
    required this.meta,
    required this.statusLabel,
  });

  final StudentProfile student;
  final String meta;
  final String statusLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      AppLeadingPicture(
        leading: AppListLeading.network(
          student.photoUrl ?? '',
          name: student.fullName,
        ),
        size: 80,
      ),
      const SizedBox(height: 14),
      AppText(
        student.fullNameWithMiddle,
        textAlign: TextAlign.center,
        style: AppTypography.heading(26, lineHeight: 32).copyWith(
          letterSpacing: -0.39,
          color: LightColors.textStrong,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      AppText(
        meta,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: AppPalette.stone500,
        ),
      ),
      const SizedBox(height: 10),
      StudentStatusPill(status: student.status, label: statusLabel),
    ],
  );
}

/// The record's status as a 26 tall pill: green while in school, stone once
/// they have left.
class StudentStatusPill extends StatelessWidget {
  const StudentStatusPill({super.key, required this.status, this.label});

  final StudentStatusFilter status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final active = status == StudentStatusFilter.active;
    final fill = active ? LightColors.successSuccessMute : AppPalette.stone100;
    final border = active ? LightColors.successSuccessThin : AppPalette.stone200;
    final dot = active ? LightColors.successSuccessDefault : AppPalette.stone500;
    final text = active ? LightColors.successSuccessText : AppPalette.stone700;
    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 9, right: 11),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          AppText(
            label ?? status.label,
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              height: 16 / 12,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
