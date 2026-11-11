import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';

/// The colour a row's icon and title take: warning for the reversible
/// actions that hold someone back, error for removal, success for restore.
enum _ActionTone { warning, success, error }

/// 9.29 / 9.29a / 9.29b · Who can use the app: the Role row for a live login,
/// then the actions that change access. Owners and admins see this only,
/// never on the owner's own row.
class StaffAccessSection extends StatelessWidget {
  const StaffAccessSection({
    super.key,
    required this.roleLabel,
    required this.isOnApp,
    required this.isPending,
    required this.isSuspended,
    this.joinedCaption,
    this.invitedCaption,
    this.onChangeRole,
    this.onToggleAccess,
    this.onCancelInvite,
    this.onRemove,
  });

  final String roleLabel;

  /// A live login that isn't suspended.
  final bool isOnApp;
  final bool isPending;
  final bool isSuspended;

  /// "Joined 3 Sep 2026", for a live login.
  final String? joinedCaption;

  /// "Invited 8 Nov", for an unused invite.
  final String? invitedCaption;

  final VoidCallback? onChangeRole;
  final VoidCallback? onToggleAccess;
  final VoidCallback? onCancelInvite;
  final VoidCallback? onRemove;

  /// A live login keeps the role and suspend rows even while suspended.
  bool get _hasLogin => isOnApp || isSuspended;

  String? get _caption {
    if (isPending) return invitedCaption;
    if (_hasLogin) return joinedCaption;
    return 'Not invited yet';
  }

  @override
  Widget build(BuildContext context) => StaffInfoSection(
    title: 'Access',
    trailing: _caption == null
        ? null
        : AppText(
            _caption!,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: LightColors.textMuted,
            ),
          ),
    rows: [
      if (_hasLogin)
        StaffInfoRow(
          icon: AppIcons.shield,
          label: 'Role',
          value: roleLabel,
          onTap: onChangeRole,
          semanticLabel: onChangeRole == null
              ? null
              : 'Change role, $roleLabel',
        ),
      if (_hasLogin)
        _AccessActionRow(
          key: const ValueKey('access-toggle'),
          icon: isSuspended ? AppIcons.lockOpen : AppIcons.circlePause,
          tone: isSuspended ? _ActionTone.success : _ActionTone.warning,
          title: isSuspended ? 'Restore access' : 'Suspend access',
          caption: isSuspended
              ? 'They can sign in again.'
              : "They stay on the list but can't sign in.",
          onTap: onToggleAccess,
        ),
      if (isPending)
        _AccessActionRow(
          key: const ValueKey('access-cancel'),
          icon: AppIcons.circleX,
          tone: _ActionTone.warning,
          title: 'Cancel invite',
          caption: 'The code stops working. They stay on the list.',
          onTap: onCancelInvite,
        ),
      _AccessActionRow(
        key: const ValueKey('access-remove'),
        icon: AppIcons.userMinus,
        tone: _ActionTone.error,
        title: 'Remove from staff list',
        caption: _hasLogin
            ? 'Also removes their login.'
            : 'Their record is removed. Nothing else changes.',
        onTap: onRemove,
      ),
    ],
  );
}

/// A 64 row with a 20 icon slot, a tinted title over its quiet explanation,
/// and the bouncy press every tappable surface uses.
class _AccessActionRow extends StatelessWidget {
  const _AccessActionRow({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final _ActionTone tone;
  final String title;
  final String caption;
  final VoidCallback? onTap;

  Color get _color => switch (tone) {
    _ActionTone.warning => LightColors.warningWarningText,
    _ActionTone.success => LightColors.successSuccessText,
    _ActionTone.error => LightColors.errorErrorText,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: '$title. $caption',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onTap,
      isDisabled: onTap == null,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: AppIcon(icon, size: 18, color: _color),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LightColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
