import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_text.dart';

/// Placeholder for [AdminProfileModel.avatarUrl] — picker to be wired later.
class CreateAccountStepProfileImage extends StatelessWidget {
  const CreateAccountStepProfileImage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Profile photo',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).padding(bottom: AppSpacing.sm),
        AppText(
          'You can add a profile photo later. We\'ll keep this step empty for now.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
