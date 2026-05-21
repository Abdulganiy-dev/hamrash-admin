import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_text.dart';

class DeleteResolutionHeadline extends StatelessWidget {
  const DeleteResolutionHeadline({
    super.key,
    required this.entityDisplayName,
    required this.clearanceMessage,
  });

  final String entityDisplayName;
  final String clearanceMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Before you can delete',
          colorType: AppTextColor.textMute,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 2),
        AppText(
          '"$entityDisplayName"',
          colorType: AppTextColor.textInverted,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppText(
          clearanceMessage,
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ),
      ],
    );
  }
}
