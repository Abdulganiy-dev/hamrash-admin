import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';

/// The one badge that says where a staff member stands: the owner, on the
/// app, a code ready to share, no login, or suspended.
///
/// The list's pill is flat and a step smaller (9.3); the detail page keeps
/// the standard bordered [AppBadge].
class StaffStatusPill extends StatelessWidget {
  const StaffStatusPill({
    super.key,
    required this.access,
    this.detail = false,
    this.onList = false,
  });

  final StaffAccess access;

  /// The detail page says "Invite pending"; the list says "Code ready".
  final bool detail;

  /// Flat 11px pill for the staff list row.
  final bool onList;

  /// The owner is a neutral fact, not something in progress.
  AppBadgeTone get _tone => switch (access) {
    StaffAccess.owner => AppBadgeTone.neutral,
    StaffAccess.onApp => AppBadgeTone.success,
    StaffAccess.invitePending => AppBadgeTone.warning,
    StaffAccess.notOnApp => AppBadgeTone.neutral,
    StaffAccess.suspended => AppBadgeTone.error,
  };

  @override
  Widget build(BuildContext context) => AppBadge(
    detail ? access.detailLabel : access.label,
    tone: _tone,
    showBorder: !onList,
    labelStyle: onList
        ? AppTypography.overline.copyWith(letterSpacing: 0)
        : null,
  );
}
