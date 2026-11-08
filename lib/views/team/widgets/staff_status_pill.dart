import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';

/// The one badge that says where a staff member stands: the owner, on the
/// app, a code ready to share, no login, or suspended.
class StaffStatusPill extends StatelessWidget {
  const StaffStatusPill({super.key, required this.access, this.detail = false});

  final StaffAccess access;

  /// The detail page says "Invite pending"; the list says "Code ready".
  final bool detail;

  AppBadgeTone get _tone => switch (access) {
    StaffAccess.owner => AppBadgeTone.info,
    StaffAccess.onApp => AppBadgeTone.success,
    StaffAccess.invitePending => AppBadgeTone.warning,
    StaffAccess.notOnApp => AppBadgeTone.neutral,
    StaffAccess.suspended => AppBadgeTone.error,
  };

  @override
  Widget build(BuildContext context) =>
      AppBadge(detail ? access.detailLabel : access.label, tone: _tone);
}
