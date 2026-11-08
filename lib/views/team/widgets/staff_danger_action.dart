import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// The quiet red action at the bottom of a staff page, with one line saying
/// what it does and doesn't touch. Sits on its own at the bottom of the page.
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
        enableHaptic: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppSvgIcon(icon, size: 16, color: LightColors.errorErrorText),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w700,
                    color: LightColors.errorErrorText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      AppText(
        caption,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w600,
          color: LightColors.textBody,
        ),
      ),
    ],
  );
}
