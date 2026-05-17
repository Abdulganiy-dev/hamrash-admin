import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/validation_util.dart';
import 'package:hamrash_admin/viewModel/create_teacher_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';

class TeacherStepIdentity extends StatelessWidget {
  const TeacherStepIdentity({
    super.key,
    required this.viewModel,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
  });

  final CreateTeacherViewModel viewModel;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = ScaffoldInsets.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: top.bodyTopInset),
        AppText(
          "Teacher's information",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).padding(bottom: AppSpacing.lg),
        AppTextField(
          controller: firstNameController,
          label: 'First Name',
          hintText: 'Enter first name',
          textInputAction: TextInputAction.next,
          onFocus: viewModel.dismissValidationMessages,
          validator: (v) {
            if (viewModel.suppressValidationMessages) return null;
            return ValidationUtil.validateFirstName(v ?? '');
          },
        ).padding(bottom: AppSpacing.md),
        AppTextField(
          controller: lastNameController,
          label: 'Last Name',
          hintText: 'Enter last name',
          textInputAction: TextInputAction.next,
          onFocus: viewModel.dismissValidationMessages,
          validator: (v) {
            if (viewModel.suppressValidationMessages) return null;
            return ValidationUtil.validateLastName(v ?? '');
          },
        ).padding(bottom: AppSpacing.md),
        AppTextField(
          controller: emailController,
          label: 'Email (optional)',
          hintText: 'Enter email address',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFocus: viewModel.dismissValidationMessages,
        ).padding(bottom: AppSpacing.md),
        AppTextField(
          controller: phoneController,
          label: 'Phone (optional)',
          hintText: 'Enter phone number',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onFocus: viewModel.dismissValidationMessages,
        ).padding(bottom: AppSpacing.md),
      ],
    );
  }
}
