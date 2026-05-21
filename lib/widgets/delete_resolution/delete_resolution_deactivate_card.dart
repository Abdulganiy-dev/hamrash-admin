import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';

class DeleteResolutionDeactivateCard extends StatelessWidget {
  const DeleteResolutionDeactivateCard({
    super.key,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Recommended alternative',
            colorType: AppTextColor.textMute,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Deactivate instead',
            colorType: AppTextColor.textInverted,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          const SizedBox(height: 4),
          AppText(
            description,
            colorType: AppTextColor.textMute,
            fontSize: 12,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            width: double.infinity,
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
