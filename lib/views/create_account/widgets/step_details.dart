import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/validation_util.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';

/// Collects [AdminProfileModel] fields: [state], [role], and [address] (location).
class CreateAccountStepDetails extends StatelessWidget {
  const CreateAccountStepDetails({
    super.key,
    required this.stateDisplayController,
    required this.roleDisplayController,
    required this.locationController,
    required this.onStateFieldTap,
    required this.onRoleFieldTap,
  });

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
          onTap: onStateFieldTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: stateDisplayController,
              label: 'State',
              hintText: 'Select your state',
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  ValidationUtil.validateValue(value ?? '', 'State'),
              readOnly: true,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            ).padding(bottom: AppSpacing.md),
          ),
        ),
        GestureDetector(
          onTap: onRoleFieldTap,
          child: AbsorbPointer(
            child: AppTextField(
              controller: roleDisplayController,
              label: 'Role',
              hintText: 'Select your role',
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  ValidationUtil.validateValue(value ?? '', 'Role'),
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
          validator: (value) =>
              ValidationUtil.validateValue(value ?? '', 'Location'),
          maxLines: 2,
        ),
      ],
    );
  }
}
