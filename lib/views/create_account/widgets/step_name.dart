import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/validation_util.dart';
import 'package:hamrash_admin/viewModel/create_account_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';

class CreateAccountStepName extends StatelessWidget {
  const CreateAccountStepName({
    super.key,
    required this.viewModel,
    required this.fullNameController,
    required this.emailController,
    required this.genderDisplayController,
    required this.onGenderFieldTap,
    required this.phoneController,
  });

  final CreateAccountViewModel viewModel;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController genderDisplayController;
  final VoidCallback onGenderFieldTap;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Welcome, let\'s set up your profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).padding(bottom: AppSpacing.lg),

        AppTextField(
          controller: fullNameController,
          label: 'Full name',
          hintText: 'Enter your full name',
          textInputAction: TextInputAction.next,
          onFocus: viewModel.dismissValidationMessages,
          validator: (value) {
            if (viewModel.suppressValidationMessages) return null;
            if (value == null || value.isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
        ).padding(bottom: AppSpacing.md),

        AppTextField(
          controller: phoneController,
          label: 'Phone number',
          hintText: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          onFocus: viewModel.dismissValidationMessages,
          validator: (value) {
            if (viewModel.suppressValidationMessages) return null;
            return ValidationUtil.validatePhoneNumber(value ?? '');
          },
          textInputAction: TextInputAction.next,
        ).padding(bottom: AppSpacing.md),

        GestureDetector(
          onTap: () {
            viewModel.dismissValidationMessages();

            onGenderFieldTap();
          },
          child: AbsorbPointer(
            child: AppTextField(
              controller: genderDisplayController,
              label: 'Gender',
              hintText: 'Select your gender',
              textInputAction: TextInputAction.next,
              onFocus: viewModel.dismissValidationMessages,
              validator: (value) {
                if (viewModel.suppressValidationMessages) return null;
                return ValidationUtil.validateValue(value ?? '', 'Gender');
              },
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ),
        AppTextField(
          controller: emailController,
          readOnly: emailController.text.isNotEmpty,
          label: 'Email',
          hintText: 'Enter your email',
          textInputAction: TextInputAction.next,
          onFocus: viewModel.dismissValidationMessages,
          validator: (value) {
            if (viewModel.suppressValidationMessages) return null;
            return ValidationUtil.validateEmail(value ?? '');
          },
        ).padding(bottom: AppSpacing.md),
      ],
    );
  }
}
