import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// 6.2 · Above the sections while classes still have no arms.
class ArmsBanner extends StatelessWidget {
  const ArmsBanner({super.key, required this.count, this.onAddArms});

  /// Classes without arms.
  final int count;

  /// Null for people who can't change classes.
  final VoidCallback? onAddArms;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: LightColors.primaryPrimaryMute,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppPalette.aubergine100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const AppSvgIcon(
                AppSvgIcons.layers,
                size: 20,
                color: LightColors.primaryPrimaryDefault,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    count == 1
                        ? '1 class has no arms yet'
                        : '$count classes have no arms yet',
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 15,
                      color: LightColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    'Arms are the groups pupils sit in, like JSS 1A. Every '
                    'class needs at least one.',
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: LightColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (onAddArms != null) ...[
          const SizedBox(height: 12),
          AppPrimaryButton(
            height: 44,
            onPressed: onAddArms,
            child: Text(
              count == 1
                  ? 'Add arms to this class'
                  : 'Add arms to these classes',
            ),
          ),
        ],
      ],
    ),
  );
}
