import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

class DeleteResolutionAllClearCard extends StatelessWidget {
  const DeleteResolutionAllClearCard({super.key, required this.readyMessage});

  final String readyMessage;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                size: 22,
                strokeWidth: 1.8,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'All clear',
                  colorType: AppTextColor.textInverted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                const SizedBox(height: 2),
                AppText(
                  readyMessage,
                  colorType: AppTextColor.textMute,
                  fontSize: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
