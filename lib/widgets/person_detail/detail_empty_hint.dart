import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

class DetailEmptyHint extends StatelessWidget {
  const DetailEmptyHint({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showTrailingArrow = false,
    this.iconInBox = true,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showTrailingArrow;
  final bool iconInBox;

  @override
  Widget build(BuildContext context) {
    final iconSize = iconInBox ? 22.0 : 20.0;
    final iconWidget = HugeIcon(
      icon: icon,
      size: iconSize,
      strokeWidth: iconInBox ? 1.8 : 2,
      color: iconColor,
    );

    final content = AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: AppElevatedCard(
        child: Row(
          children: [
            if (iconInBox)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: iconWidget),
              )
            else
              Center(child: iconWidget),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    colorType: AppTextColor.textInverted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    subtitle,
                    colorType: AppTextColor.textMute,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
            if (showTrailingArrow)
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 20,
                strokeWidth: 2,
                color: LightColors.textTextMute,
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    ).hapticFeedback();
  }
}
