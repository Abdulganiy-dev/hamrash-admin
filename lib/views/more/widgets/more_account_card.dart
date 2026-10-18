import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// Help and sign out, at the bottom of the More tab.
class MoreAccountCard extends StatelessWidget {
  const MoreAccountCard({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Column(
      children: [
        _AccountRow(
          icon: AppSvgIcons.circleHelp,
          label: 'Help and support',
          onTap: () => AppToast.show('Help and support is coming soon'),
        ),
        const Divider(height: 1, thickness: 1, color: AppPalette.stone100),
        _AccountRow(
          icon: AppSvgIcons.logOut,
          label: 'Sign out',
          destructive: true,
          onTap: onSignOut,
        ),
      ],
    ),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final AppSvgIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? LightColors.errorErrorText
        : AppPalette.stone600;
    return BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AppSvgIcon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: AppText(
                label,
                variant: AppTextVariant.bodyLarge,
                color: destructive ? color : AppPalette.stone900,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!destructive)
              const AppSvgIcon(
                AppSvgIcons.chevronRight,
                size: 18,
                color: AppPalette.stone400,
              ),
          ],
        ),
      ),
    );
  }
}
