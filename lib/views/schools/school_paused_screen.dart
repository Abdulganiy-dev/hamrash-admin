import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_links.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// 09 · This school is paused. Hamrash suspended the school, so its records
/// are hidden until it is active again.
class SchoolPausedScreen extends StatelessWidget {
  const SchoolPausedScreen({
    super.key,
    required this.school,
    required this.onSignOut,
    this.onSwitchSchool,
  });

  final MemberSchool school;
  final VoidCallback onSignOut;

  /// Back to the picker; null when this is their only school.
  final VoidCallback? onSwitchSchool;

  Future<void> _contactSupport() async {
    if (AppLinks.supportEmail.isEmpty) {
      AppToast.show(
        'Support contact is on its way. Ask your Hamrash contact for now.',
      );
      return;
    }
    final opened = await launchUrl(
      Uri(
        scheme: 'mailto',
        path: AppLinks.supportEmail,
        queryParameters: {'subject': '${school.name} is paused'},
      ),
    );
    if (!opened) {
      AppToast.show(
        'Email Hamrash at ${AppLinks.supportEmail}',
        type: AppToastType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) => AuthScreenFrame(
    showBackButton: onSwitchSchool != null,
    onBack: onSwitchSchool,
    scrollContent: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppPalette.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LightColors.warningWarningThin),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LightColors.warningWarningMute,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const AppSvgIcon(
              AppSvgIcons.circlePause,
              size: 30,
              color: LightColors.warningWarningText,
            ),
          ),
        ),
        const SizedBox(height: 28),
        AppText(
          '${school.name} · Paused'.toUpperCase(),
          style: AppTypography.overline.copyWith(
            color: LightColors.warningWarningText,
          ),
        ),
        const SizedBox(height: AppSpacing.ms),
        const AppText('This school is paused', variant: AppTextVariant.h1),
        const SizedBox(height: AppSpacing.ms),
        AppText(
          "Hamrash has paused ${school.name}'s account, so its records are hidden for now. Nothing has been deleted. Everything comes back as soon as the school is active again.",
          variant: AppTextVariant.bodyLarge,
          colorType: AppTextColor.textBody,
        ),
      ],
    ),
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          size: AppButtonSize.large,
          onPressed: _contactSupport,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(AppSvgIcons.messageSquare, size: 20),
              SizedBox(width: 10),
              AppText('Contact Hamrash support'),
            ],
          ),
        ),
        if (onSwitchSchool != null) ...[
          const SizedBox(height: AppSpacing.ms),
          AppSecondaryButton(
            size: AppButtonSize.large,
            onPressed: onSwitchSchool,
            child: const AppText('Switch school'),
          ),
        ],
        const SizedBox(height: AppSpacing.ms),
        AuthTextLink(label: 'Sign out', onTap: onSignOut),
      ],
    ),
  );
}
