import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/create_teacher_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';

class TeacherStepPersonal extends StatelessWidget {
  const TeacherStepPersonal({
    super.key,
    required this.viewModel,
    required this.genderDisplayController,
    required this.stateDisplayController,
    required this.addressController,
    required this.onGenderFieldTap,
    required this.onStateFieldTap,
  });

  final CreateTeacherViewModel viewModel;
  final TextEditingController genderDisplayController;
  final TextEditingController stateDisplayController;
  final TextEditingController addressController;
  final VoidCallback onGenderFieldTap;
  final VoidCallback onStateFieldTap;

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
              controller: genderDisplayController,
              label: 'Gender',
              hintText: 'Select gender',
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ).hapticFeedback(),
        GestureDetector(
          onTap: onStateFieldTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: stateDisplayController,
              label: 'State',
              hintText: 'Select state',
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ).hapticFeedback(),
        AppTextField(
          controller: addressController,
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
