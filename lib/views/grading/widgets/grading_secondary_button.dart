import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';

/// The Grading pages' second action ("Copy grades from another section",
/// "Change to WAEC grades"): the app's secondary button with a small leading
/// icon. Stack it 16px under the primary action.
class GradingSecondaryButton extends StatelessWidget {
  const GradingSecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.height,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double? height;

  @override
  Widget build(BuildContext context) => AppSecondaryButton(
    height: height,
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 16, color: LightColors.textStrong),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
