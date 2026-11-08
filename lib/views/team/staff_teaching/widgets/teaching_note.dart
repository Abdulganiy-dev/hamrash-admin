import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';

/// The tinted block above a teaching sheet's button: what saving would do,
/// in the tone the case carries.
class TeachingNote extends StatelessWidget {
  const TeachingNote({super.key, required this.note, required this.tone});

  final String note;
  final TeachingTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, ink, icon) = switch (tone) {
      TeachingTone.success => (
        LightColors.successSuccessMute,
        LightColors.successSuccessText,
        AppIcons.check,
      ),
      TeachingTone.warning => (
        LightColors.warningWarningMute,
        LightColors.warningWarningText,
        AppIcons.circleAlert,
      ),
      TeachingTone.error => (
        LightColors.errorErrorMute,
        LightColors.errorErrorText,
        AppIcons.circleAlert,
      ),
      TeachingTone.neutral => (
        AppPalette.stone100,
        LightColors.textBody,
        AppIcons.info,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.ms),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brControl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppIcon(icon, size: 16, color: ink),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText(
              note,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
