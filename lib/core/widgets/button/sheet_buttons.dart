import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:flutter/material.dart';

class SheetButton extends StatelessWidget {

  const SheetButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.labelColor,
    this.onPressed,
  
  });

  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color labelColor;
  final VoidCallback? onPressed;

  static Widget badgeIcon({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.brR24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(height: AppSpacing.sm),
            AppText(
              label,
              color: labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
