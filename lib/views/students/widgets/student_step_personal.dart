import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/create_student_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';

class StudentStepPersonal extends StatelessWidget {
  const StudentStepPersonal({
    super.key,
    required this.viewModel,
    required this.onGenderFieldTap,
    required this.onStateFieldTap,
    required this.onDobFieldTap,
  });

  final CreateStudentViewModel viewModel;
  final VoidCallback onGenderFieldTap;
  final VoidCallback onStateFieldTap;
  final VoidCallback onDobFieldTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = ScaffoldInsets.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: top.bodyTopInset),
        AppText(
          'Personal details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).padding(bottom: AppSpacing.xs),
        AppText(
          'All fields on this step are optional.',
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ).padding(bottom: AppSpacing.lg),
        GestureDetector(
          onTap: onGenderFieldTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: viewModel.genderDisplayController,
              label: 'Gender',
              hintText: 'Select gender',
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ).hapticFeedback(),
        GestureDetector(
          onTap: onDobFieldTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: viewModel.dobDisplayController,
              label: 'Date of birth',
              hintText: 'Pick a date',
              readOnly: true,
              suffixIcon:
                  const Icon(CupertinoIcons.calendar, size: 18),
            ).padding(bottom: AppSpacing.md),
          ),
        ).hapticFeedback(),
        GestureDetector(
          onTap: onStateFieldTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: viewModel.stateDisplayController,
              label: 'State',
              hintText: 'Select state',
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ).hapticFeedback(),
        AppTextField(
          controller: viewModel.addressController,
          label: 'Address (optional)',
          hintText: 'Street, city, or area',
          textInputAction: TextInputAction.done,
          onFocus: viewModel.dismissValidationMessages,
          maxLines: 2,
        ),
      ],
    );
  }
}
