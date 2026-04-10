import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/validation_util.dart';
import 'package:hamrash_admin/viewModel/create_account_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';

/// Collects [AdminProfileModel] fields: [state], [role], and [address] (location).
class CreateAccountStepDetails extends StatelessWidget {
  const CreateAccountStepDetails({
    super.key,
    required this.viewModel,
    required this.stateDisplayController,
    required this.roleDisplayController,
    required this.locationController,
    required this.onStateFieldTap,
    required this.onRoleFieldTap,
  });

  final CreateAccountViewModel viewModel;
  final TextEditingController stateDisplayController;
  final TextEditingController roleDisplayController;
  final TextEditingController locationController;
  final VoidCallback onStateFieldTap;
  final VoidCallback onRoleFieldTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Where you work and what you do',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).padding(bottom: AppSpacing.lg),
        GestureDetector(
          onTap: () {
            viewModel.dismissValidationMessages();
            onStateFieldTap();
          },
          child: AbsorbPointer(
            child: AppTextField(
              controller: stateDisplayController,
              label: 'State',
              hintText: 'Select your state',
              textInputAction: TextInputAction.next,
              onFocus: viewModel.dismissValidationMessages,
              validator: (value) {
                if (viewModel.suppressValidationMessages) return null;
                return ValidationUtil.validateValue(value ?? '', 'State');
              },
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ),
        GestureDetector(
          onTap: () {
            viewModel.dismissValidationMessages();
            onRoleFieldTap();
          },
          child: AbsorbPointer(
            child: AppTextField(
              controller: roleDisplayController,
              label: 'Role',
              hintText: 'Select your role',
              textInputAction: TextInputAction.next,
              onFocus: viewModel.dismissValidationMessages,
              validator: (value) {
                if (viewModel.suppressValidationMessages) return null;
                return ValidationUtil.validateValue(value ?? '', 'Role');
              },
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ),
        AppTextField(
          controller: locationController,
          label: 'Location',
          hintText: 'City, area, or full address',
          textInputAction: TextInputAction.done,
          onFocus: viewModel.dismissValidationMessages,
          validator: (value) {
            if (viewModel.suppressValidationMessages) return null;
            return ValidationUtil.validateValue(value ?? '', 'Location');
          },
          maxLines: 2,
        ),
      ],
    );
  }
}
