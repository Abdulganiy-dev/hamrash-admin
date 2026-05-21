import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/create_student_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';

class StudentStepAcademic extends StatelessWidget {
  const StudentStepAcademic({
    super.key,
    required this.viewModel,
    required this.onClassFieldTap,
    required this.onAdmissionDateTap,
  });

  final CreateStudentViewModel viewModel;
  final VoidCallback onClassFieldTap;
  final VoidCallback onAdmissionDateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = ScaffoldInsets.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: top.bodyTopInset),
        AppText(
          'Academic details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).padding(bottom: AppSpacing.xs),
        AppText(
          'You can change these later from the student profile.',
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ).padding(bottom: AppSpacing.lg),
        GestureDetector(
          onTap: onClassFieldTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: viewModel.classDisplayController,
              label: 'Class',
              hintText: 'Select a class',
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ).hapticFeedback(),
        AppTextField(
          controller: viewModel.admissionNumberController,
          label: 'Admission number (optional)',
          hintText: 'School-issued ID',
          textInputAction: TextInputAction.next,
          onFocus: viewModel.dismissValidationMessages,
        ).padding(bottom: AppSpacing.md),
        GestureDetector(
          onTap: onAdmissionDateTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: viewModel.admissionDateDisplayController,
              label: 'Admission date (optional)',
              hintText: 'Pick a date',
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.calendar, size: 18),
            ).padding(bottom: AppSpacing.md),
          ),
        ).hapticFeedback(),
      ],
    );
  }
}
