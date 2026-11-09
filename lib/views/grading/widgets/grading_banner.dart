import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

enum GradingBannerTone { success, warning, plain }

/// 9.2, 9.8, 9.9 · A tinted card with a title and a line under it: whether
/// the grade scale covers 0 to 100, what's missing, or that the page is
/// read only.
class GradingBanner extends StatelessWidget {
  const GradingBanner({
    super.key,
    required this.tone,
    required this.title,
    required this.message,
    this.icon,
  });

  final GradingBannerTone tone;
  final String title;
  final String message;

  /// Overrides the tone's icon. Null keeps the tone's own (or none).
  final IconData? icon;

  Color get _fill => switch (tone) {
    GradingBannerTone.success => LightColors.successSuccessMute,
    GradingBannerTone.warning => LightColors.warningWarningMute,
    GradingBannerTone.plain => AppPalette.stone50,
  };

  Color get _border => switch (tone) {
    GradingBannerTone.success => LightColors.successSuccessThin,
    GradingBannerTone.warning => LightColors.warningWarningThin,
    GradingBannerTone.plain => AppPalette.stone200,
  };

  Color get _titleColor => switch (tone) {
    GradingBannerTone.success => LightColors.successSuccessText,
    GradingBannerTone.warning => LightColors.warningWarningText,
    GradingBannerTone.plain => LightColors.textStrong,
  };

  Color get _iconColor => switch (tone) {
    GradingBannerTone.success => LightColors.successSuccessDefault,
    GradingBannerTone.warning => LightColors.warningWarningDefault,
    GradingBannerTone.plain => LightColors.textBody,
  };

  IconData? get _icon =>
      icon ??
      switch (tone) {
        GradingBannerTone.success => AppIcons.circleCheck,
        GradingBannerTone.warning => AppIcons.circleAlert,
        GradingBannerTone.plain => null,
      };

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _fill,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_icon case final icon?) ...[
              AppIcon(icon, size: 18, color: _iconColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: AppText(
                title,
                style: AppTypography.subtitle.copyWith(
                  fontSize: 15,
                  color: _titleColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppText(
          message,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: LightColors.textBody,
          ),
        ),
      ],
    ),
  );
}
