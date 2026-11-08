import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// The quiet red action at the bottom of a staff page, with one line saying
/// what it does and doesn't touch.
class StaffDangerAction extends StatelessWidget {
  const StaffDangerAction({
    super.key,
    required this.label,
    required this.caption,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final String caption;
  final VoidCallback? onPressed;
  final AppSvgIconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      BouncyButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.ms,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppSvgIcon(icon, size: 16, color: LightColors.errorErrorText),
                const SizedBox(width: AppSpacing.sm),
              ],
              AppText(
                label,
                style: AppTypography.button.copyWith(
                  color: LightColors.errorErrorText,
                ),
              ),
            ],
          ),
        ),
      ),
      AppText(
        caption,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(color: AppPalette.stone500),
      ),
    ],
  );
}
