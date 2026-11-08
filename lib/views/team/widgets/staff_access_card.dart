import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// Who can use the app, for someone who already has a login: change the role,
/// or suspend and restore access. Owners and admins see this card only, and
/// never on the owner's own record.
class StaffAccessCard extends StatelessWidget {
  const StaffAccessCard({
    super.key,
    required this.roleLabel,
    required this.isSuspended,
    required this.onChangeRole,
    required this.onToggleAccess,
  });

  final String roleLabel;
  final bool isSuspended;
  final VoidCallback onChangeRole;
  final VoidCallback onToggleAccess;

  static const _border = AppPalette.stone200;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.brCard,
    child: Container(
      decoration: BoxDecoration(
        color: AppPalette.white,
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: BouncyButton(
              onPressed: onChangeRole,
              pressedScale: 0.98,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'Change role',
                        style: AppTypography.body.copyWith(
                          fontSize: 16,
                          height: 22 / 16,
                          fontWeight: FontWeight.w700,
                          color: LightColors.textStrong,
                        ),
                      ),
                    ),
                    AppText(
                      roleLabel,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w600,
                        color: LightColors.textBody,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const AppIcon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: AppPalette.stone400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppDivider(),
          BouncyButton(
            onPressed: onToggleAccess,
            pressedScale: 0.98,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.ms,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    isSuspended ? 'Restore access' : 'Suspend access',
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isSuspended
                              ? LightColors.successSuccessText
                              : LightColors.warningWarningText,
                    ),
                  ),
                  AppText(
                    isSuspended
                        ? 'They can sign in again.'
                        : "They stay on the list but can't sign in.",
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                      color: LightColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
