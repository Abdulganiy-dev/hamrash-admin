import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_photo_field.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/parent_card.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/step_lead.dart';

/// 11.11 · Step 5: everything entered, in section cards with Edit, before
/// Register. Nothing has been saved yet.
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key, required this.model});

  final AddStudentViewModel model;

  AppSectionAction _edit(String section, AddStudentStep step) =>
      AppSectionAction(
        label: 'Edit',
        icon: AppIcons.pencil,
        semanticLabel: 'Edit $section',
        onPressed: model.registering ? null : () => model.edit(step),
      );

  String get _photoValue {
    final photo = model.studentPhoto;
    if (photo.isAdded) return 'Added';
    if (photo.isUploading) return 'Uploading…';
    if (photo.hasFailed) return "Didn't upload";
    return 'Not added';
  }

  @override
  Widget build(BuildContext context) {
    final photo = model.studentPhoto;
    final middle = model.middleName.text.trim();
    final number = model.admissionNumber.text.trim();
    final chosen = model.chosenSubjects;
    return StepScroll(
      children: [
        Column(
          children: [
            AppPhotoAvatar(
              name: model.studentName,
              status: photo.status,
              image: photo.preview,
              size: AppPhotoFieldSize.hero,
              showBadge: false,
            ),
            const SizedBox(height: 14),
            AppText(
              model.studentName,
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.w800,
                height: 30 / 24,
                color: LightColors.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            AppText(
              'Nothing is saved until you register.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: LightColors.textMuted),
            ),
          ],
        ),
        AppSectionCard(
          title: 'Student',
          action: _edit('the student', AddStudentStep.student),
          children: [
            if (middle.isNotEmpty)
              ReviewRow(value: middle, label: 'Middle name'),
            ReviewRow(value: model.gender?.label ?? '', label: 'Gender'),
            ReviewRow(
              value: model.dateOfBirth == null
                  ? ''
                  : AppDateFormat.dayMonthYear(model.dateOfBirth!),
              label: 'Date of birth',
            ),
            ReviewRow(
              value: AppDateFormat.dayMonthYear(model.admissionDate),
              label: 'Admission date',
            ),
            ReviewRow(
              value: number.isEmpty ? 'Given when you register' : number,
              label: 'Admission number',
            ),
            ReviewRow(
              value: _photoValue,
              label: 'Photo',
              muted: !photo.isAdded,
            ),
          ],
        ),
        AppSectionCard(
          title: 'Parents',
          caption: '${model.parents.length} added',
          action: _edit('parents', AddStudentStep.parents),
          children: [
            for (var i = 0; i < model.parents.length; i++)
              ReviewRow(
                leading: AppLeadingPicture(
                  leading: parentLeading(model.parents[i]),
                  size: 40,
                ),
                value: model.parents[i].displayName,
                label: model.parents[i].relationship.label,
                trailing: i == model.mainIndex ? 'Main contact' : null,
              ),
          ],
        ),
        AppSectionCard(
          title: 'Class and subjects',
          caption: model.sessionName,
          action: _edit('class and subjects', AddStudentStep.placement),
          children: [
            ReviewRow(value: model.armLabel, label: 'Class and arm'),
            if (model.optionalSubjects.isNotEmpty)
              ReviewRow(
                value: chosen.isEmpty
                    ? 'None chosen'
                    : chosen.map((subject) => subject.name).join(', '),
                label: 'Optional subjects',
                muted: chosen.isEmpty,
                trailing: chosen.isEmpty ? null : '${chosen.length} chosen',
              ),
          ],
        ),
      ],
    );
  }
}

/// One 60 tall row of a review card: the value over its label, with an
/// optional picture before and a muted note after.
class ReviewRow extends StatelessWidget {
  const ReviewRow({
    super.key,
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.muted = false,
  });

  final String value;
  final String label;
  final Widget? leading;
  final String? trailing;

  /// "Not added": the value in the disabled colour.
  final bool muted;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 60),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (leading case final leading?) ...[
            leading,
            const SizedBox(width: AppSpacing.ms),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 15,
                    color: muted
                        ? LightColors.textDisabled
                        : LightColors.textStrong,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                AppText(
                  label,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing case final trailing?) ...[
            const SizedBox(width: AppSpacing.ms),
            AppText(
              trailing,
              style: AppTypography.label.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
