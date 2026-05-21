import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

class DeleteResolutionSectionShell extends StatelessWidget {
  const DeleteResolutionSectionShell({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.child,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Center(
              child: HugeIcon(
                icon: icon,
                size: 24,
                strokeWidth: 2,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppText(
                title,
                colorType: AppTextColor.textInverted,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: LightColors.errorErrorDefault.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AppText(
                count.toString(),
                color: LightColors.errorErrorDefault,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}
