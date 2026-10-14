import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Why a sheet's save didn't work, above its button.
class SheetError extends StatelessWidget {
  const SheetError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightColors.errorErrorMute,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.circleAlert500,
              size: 16,
              color: LightColors.errorErrorText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              message,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.errorErrorText,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
