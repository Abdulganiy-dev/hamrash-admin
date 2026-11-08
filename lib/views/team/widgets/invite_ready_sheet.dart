import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_invite_code.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/share_invite.dart';

/// 8.8 · Shown right after `invite_staff` returns: the code, the exact
/// message to send, and one button that opens the phone's share sheet.
class InviteReadySheet extends StatelessWidget {
  const InviteReadySheet({
    super.key,
    required this.firstName,
    required this.role,
    required this.code,
    required this.message,
  });

  final String firstName;
  final OrganizationMemberRole role;

  /// Raw 8 characters: `K7M2QX9P`.
  final String code;

  /// The exact words the person will receive.
  final String message;

  @override
  Widget build(BuildContext context) {
    final labelName = firstName.toUpperCase();
    return AppSheet(
      title: "$firstName's invite is ready",
      subtitle: "Hamrash doesn't send it. You do.",
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InviteCodeDisplay(
            code: code,
            caption: 'Invite code · ${role.teamLabel}',
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            'WHAT $labelName RECEIVES',
            style: AppTypography.overline.copyWith(
              color: LightColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFlatCard(
            child: AppText(
              message,
              style: AppTypography.body.copyWith(
                fontSize: 15,
                height: 22 / 15,
                color: LightColors.textBody,
              ),
            ),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            useGradient: true,
            height: 52,
            onPressed:
                () => shareInvite(message, origin: shareOriginOf(context)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(AppIcons.share, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text('Share invite'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BouncyButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppText(
                'Done',
                textAlign: TextAlign.center,
                style: AppTypography.button.copyWith(
                  color: LightColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
