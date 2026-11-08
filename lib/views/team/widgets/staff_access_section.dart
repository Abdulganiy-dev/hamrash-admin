import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';

/// Who can use the app, for someone who already has a login: the Role row
/// (tap to change), and a tonal Suspend / Restore access button with a line
/// under it. Owners and admins see this only, never on the owner's own row.
class StaffAccessSection extends StatelessWidget {
  const StaffAccessSection({
    super.key,
    required this.roleLabel,
    required this.isSuspended,
    required this.onChangeRole,
    required this.onToggleAccess,
    this.joinedCaption,
  });

  final String roleLabel;
  final bool isSuspended;
  final String? joinedCaption;
  final VoidCallback onChangeRole;
  final VoidCallback onToggleAccess;

  @override
  Widget build(BuildContext context) {
    final tone =
        isSuspended
            ? (
              fill: LightColors.successSuccessMute,
              text: LightColors.successSuccessText,
              icon: AppIcons.lockOpen,
            )
            : (
              fill: LightColors.warningWarningMute,
              text: LightColors.warningWarningText,
              icon: AppIcons.circlePause,
            );

    return StaffInfoSection(
      title: 'Access',
      trailing:
          joinedCaption == null
              ? null
              : AppText(
                joinedCaption!,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LightColors.textMuted,
                ),
              ),
      rows: [
        StaffInfoRow(
          icon: AppIcons.shield,
          label: 'Role',
          value: roleLabel,
          onTap: onChangeRole,
          semanticLabel: 'Change role, $roleLabel',
        ),
        const StaffRowDivider(),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: isSuspended ? 'Restore access' : 'Suspend access',
          excludeSemantics: true,
          child: BouncyButton(
            onPressed: onToggleAccess,
            child: Container(
              key: const ValueKey('access-toggle'),
              height: 48,
              decoration: BoxDecoration(
                color: tone.fill,
                borderRadius: AppRadius.brLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(tone.icon, size: 16, color: tone.text),
                  const SizedBox(width: 7),
                  AppText(
                    isSuspended ? 'Restore access' : 'Suspend access',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 18 / 14,
                      color: tone.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        AppText(
          isSuspended
              ? 'They can sign in again.'
              : "They stay on the list but can't sign in.",
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: LightColors.textBody,
          ),
        ),
      ],
    );
  }
}
