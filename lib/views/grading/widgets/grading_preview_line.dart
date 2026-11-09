import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// 9.3, 9.5 · The quiet line in a sheet that shows what saving will do:
/// "Total becomes 120 marks, from 100 now", "Goes up to 69.99, where A
/// starts".
class GradingPreviewLine extends StatelessWidget {
  const GradingPreviewLine({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppPalette.stone50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        AppText(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: LightColors.textMuted,
          ),
        ),
        AppText(
          value,
          style: AppTypography.subtitle.copyWith(color: LightColors.textStrong),
        ),
      ],
    ),
  );
}
