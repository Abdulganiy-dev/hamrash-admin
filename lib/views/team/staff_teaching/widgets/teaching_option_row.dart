import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// One choice on the Teaching setup sheet: a tinted icon tile, its title and
/// caption, and a chevron.
class TeachingOptionRow extends StatelessWidget {
  const TeachingOptionRow({
    super.key,
    required this.icon,
    required this.tileColor,
    required this.iconColor,
    required this.title,
    required this.caption,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color tileColor;
  final Color iconColor;
  final String title;

  /// "JSS 1A · Lead teacher", "3 subjects this session".
  final String caption;

  final VoidCallback onTap;

  /// False on a closed session: the row is shown but can't be opened.
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: '$title, $caption',
    excludeSemantics: true,
    child: BouncyButton(
      pressedScale: 0.98,
      onPressed: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.ms,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled ? tileColor : AppPalette.stone100,
                borderRadius: AppRadius.brChip,
              ),
              child: AppIcon(
                icon,
                size: 20,
                color: enabled ? iconColor : AppPalette.stone400,
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    title,
                    style: AppTypography.subtitle.copyWith(
                      color: enabled
                          ? LightColors.textStrong
                          : LightColors.textDisabled,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    caption,
                    style: AppTypography.caption.copyWith(
                      color: enabled
                          ? LightColors.textBody
                          : LightColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: AppSpacing.sm),
              const AppIcon(
                AppIcons.chevronRight,
                size: 18,
                color: AppPalette.stone400,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
