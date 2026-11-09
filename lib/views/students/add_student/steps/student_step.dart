import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_date_fields.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/step_lead.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/wizard_photo_field.dart';
import 'package:hamrash_admin/views/team/widgets/staff_form_fields.dart';

/// 11.3 · Step 1: who the student is. Names, gender and date of birth are
/// needed; the middle name, admission number and photo are optional.
class StudentStep extends StatelessWidget {
  const StudentStep({super.key, required this.model});

  final AddStudentViewModel model;

  static final _optional = AppTypography.label.copyWith(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: LightColors.textMuted,
  );

  @override
  Widget build(BuildContext context) => StepScroll(
    children: [
      StepLead(
        eyebrow: model.stepEyebrow(AddStudentStep.student),
        title: 'Who is the student?',
      ),
      WizardPhotoField(
        model: model,
        draft: model.studentPhoto,
        name: model.studentName,
        title: model.studentName,
        sheetTitle: 'Photo of ${model.studentFirstName}',
        emptyCaption: 'Optional. You can add it later.',
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'First name',
                  hintText: 'Chioma',
                  controller: model.firstName,
                  errorText: model.firstNameProblem,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => model.changed(),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: AppTextField(
                  label: 'Last name',
                  hintText: 'Okafor',
                  controller: model.lastName,
                  errorText: model.lastNameProblem,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => model.changed(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Middle name',
            isOptional: true,
            optionalStyle: _optional,
            hintText: 'Middle name',
            controller: model.middleName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => model.changed(),
          ),
        ],
      ),
      StaffGenderField(value: model.gender, onChanged: model.pickGender),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppDateField(
              label: 'Date of birth',
              value: model.dateOfBirth,
              placeholder: 'Select date',
              firstDate: DateTime(model.today.year - 30),
              lastDate: model.today,
              valueFormatter: AppDateFormat.dayMonthYear,
              onChanged: model.pickDateOfBirth,
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: AppDateField(
              label: 'Admission date',
              value: model.admissionDate,
              placeholder: 'Select date',
              firstDate: DateTime(model.today.year - 30),
              lastDate: DateTime(model.today.year + 1, 12, 31),
              valueFormatter: AppDateFormat.dayMonthYear,
              onChanged: model.pickAdmissionDate,
            ),
          ),
        ],
      ),
      AppTextField(
        label: 'Admission number',
        isOptional: true,
        optionalStyle: _optional,
        hintText: model.admissionNumberHint,
        helperText:
            'Leave blank and the next number is given when you register.',
        controller: model.admissionNumber,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        onChanged: (_) => model.changed(),
      ),
    ],
  );
}
