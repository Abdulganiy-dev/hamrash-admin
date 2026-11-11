import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';

/// 9.29 / 9.29a / 9.29b · Who can use the app, for one staff member. A thin
/// layer over the shared [AccessCards]: it turns the person's state into the
/// app cards and the Actions rows each stage needs.
///
///  * not on app: the app row (tap to invite), then Change status and Remove;
///  * code ready: the app and its role, then Change status, Cancel invite
///    and Remove;
///  * on app: the app cards, then Add role, Change status, Suspend access
///    and Remove;
///  * suspended: as on app, with Restore access and no Add role.
///
/// Owners and admins see this only, never on the owner's own row.
class StaffAccessSection extends StatelessWidget {
  const StaffAccessSection({
    super.key,
    required this.apps,
    required this.isOnApp,
    required this.isPending,
    required this.isSuspended,
    this.joinedCaption,
    this.invitedCaption,
    this.onChangeStatus,
    this.onAddRole,
    this.onToggleAccess,
    this.onCancelInvite,
    this.onRemove,
  });

  /// One entry per app their roles span, built by the view model.
  final List<AccessApp> apps;

  /// A live login that isn't suspended.
  final bool isOnApp;
  final bool isPending;
  final bool isSuspended;

  /// "Joined 3 Sep 2026", for a live login.
  final String? joinedCaption;

  /// "Invited 8 Nov", for an unused invite.
  final String? invitedCaption;

  final VoidCallback? onChangeStatus;

  /// Null hides the row: only someone active on the app can get another
  /// role, and only a leader who may add one.
  final VoidCallback? onAddRole;
  final VoidCallback? onToggleAccess;
  final VoidCallback? onCancelInvite;
  final VoidCallback? onRemove;

  bool get _hasLogin => isOnApp || isSuspended;

  /// "Joined 3 Sep 2026" or "Invited 8 Nov". The state itself lives on the
  /// app row and the hero pill; this line only adds the date.
  String? get _caption {
    if (isPending) return invitedCaption;
    if (_hasLogin) return joinedCaption;
    return null;
  }

  @override
  Widget build(BuildContext context) => AccessCards(
    caption: _caption,
    apps: apps,
    actions: [
      if (isOnApp && onAddRole != null)
        AccessAction(
          key: const ValueKey('access-add-role'),
          icon: AppIcons.shieldPlus,
          title: 'Add role',
          caption: 'They keep the roles they have.',
          onTap: onAddRole,
        ),
      AccessAction(
        key: const ValueKey('access-status'),
        icon: AppIcons.clock,
        title: 'Change status',
        caption: 'Active, on leave or exited.',
        onTap: onChangeStatus,
      ),
      if (_hasLogin)
        AccessAction(
          key: const ValueKey('access-toggle'),
          icon: isSuspended ? AppIcons.lockOpen : AppIcons.circlePause,
          tone: isSuspended
              ? AccessActionTone.success
              : AccessActionTone.warning,
          title: isSuspended ? 'Restore access' : 'Suspend access',
          caption: isSuspended
              ? 'They can sign in again.'
              : "They stay on the list but can't sign in.",
          onTap: onToggleAccess,
        ),
      if (isPending)
        AccessAction(
          key: const ValueKey('access-cancel'),
          icon: AppIcons.circleX,
          tone: AccessActionTone.warning,
          title: 'Cancel invite',
          caption: 'The code stops working. They stay on the list.',
          onTap: onCancelInvite,
        ),
      AccessAction(
        key: const ValueKey('access-remove'),
        icon: AppIcons.userMinus,
        tone: AccessActionTone.error,
        title: 'Remove from staff list',
        caption: _hasLogin
            ? 'Also removes their login.'
            : 'Their record is removed. Nothing else changes.',
        onTap: onRemove,
      ),
    ],
  );
}
