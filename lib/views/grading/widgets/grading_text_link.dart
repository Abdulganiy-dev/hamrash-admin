import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_icon_label.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// A quiet aubergine text action with a small leading icon, 44 tall. For a
/// real alternative that sits on its own, not stacked under a primary button
/// (use [GradingSecondaryButton] there).
class GradingTextLink extends StatelessWidget {
  const GradingTextLink({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => BouncyButton(
    onPressed: onPressed,
    child: SizedBox(
      height: 44,
      child: Center(
        child: AppIconLabel(
          icon: icon,
          label: label,
          iconColor: LightColors.primaryPrimaryText,
          iconSize: 16,
          gap: 8,
          hugContent: true,
          style: AppTypography.body.copyWith(
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w700,
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ),
    ),
  );
}
