import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// The staff page's status pill: a 7px dot, a bordered 26 tall pill and the
/// short state label. The list keeps its own smaller flat pill.
class StaffDetailStatusPill extends StatelessWidget {
  const StaffDetailStatusPill({super.key, required this.access});

  final StaffAccess access;

  String get _label => switch (access) {
    StaffAccess.owner || StaffAccess.onApp => 'On app',
    StaffAccess.invitePending => 'Invite pending',
    StaffAccess.notOnApp => 'Not on app',
    StaffAccess.suspended => 'Suspended',
  };

  ({Color fill, Color border, Color dot, Color text}) get _tone =>
      switch (access) {
        StaffAccess.owner || StaffAccess.onApp => (
          fill: LightColors.successSuccessMute,
          border: LightColors.successSuccessThin,
          dot: LightColors.successSuccessDefault,
          text: LightColors.successSuccessText,
        ),
        StaffAccess.invitePending => (
          fill: LightColors.warningWarningMute,
          border: LightColors.warningWarningThin,
          dot: LightColors.warningWarningDefault,
          text: LightColors.warningWarningText,
        ),
        StaffAccess.suspended => (
          fill: LightColors.errorErrorMute,
          border: LightColors.errorErrorThin,
          dot: LightColors.errorErrorDefault,
          text: LightColors.errorErrorText,
        ),
        StaffAccess.notOnApp => (
          fill: AppPalette.stone100,
          border: AppPalette.stone200,
          dot: AppPalette.stone500,
          text: AppPalette.stone700,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 9, right: 11),
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: tone.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          AppText(
            _label,
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              height: 16 / 12,
              color: tone.text,
            ),
          ),
        ],
      ),
    );
  }
}
