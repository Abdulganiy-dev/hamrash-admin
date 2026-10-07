import 'package:hamrash_admin/core/assets_util.dart';
import 'package:hamrash_admin/core/bottomSheets/non_dismissible_glass_sheet_route.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:flutter/material.dart';

import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// A reusable success modal that slides up from the bottom.
///
/// By default renders a single tertiary "OK" button. When
/// [primaryActionLabel] is set, that button replaces "OK". When
/// [secondaryActionLabel] is also set, both buttons render stacked
/// (primary on top).
///
/// Usage:
/// ```dart
/// // Single OK (default)
/// SuccessModal.show(context, message: 'Saved.');
///
/// // Two actions
/// SuccessModal.show(
///   context,
///   title: 'Student Registered',
///   message: 'John Doe has been registered successfully.',
///   primaryActionLabel: 'Go to Dashboard',
///   onPrimaryAction: () => Navigator.popUntil(context, (r) => r.isFirst),
///   secondaryActionLabel: 'Register Another',
///   onSecondaryAction: () => viewModel.resetForm(),
/// );
/// ```
class SuccessModal extends StatelessWidget {
  final String message;
  final String? title;
  final List<List<dynamic>>? icon;
  final Duration? autoDismissDuration;
  final VoidCallback? onDismiss;

  /// Primary action label. When set, replaces the default "OK" button.
  final String? primaryActionLabel;

  /// Callback for the primary action. The modal is dismissed automatically
  /// before this fires.
  final VoidCallback? onPrimaryAction;

  /// Secondary action label. When set alongside [primaryActionLabel], a
  /// second outlined button renders below the primary one.
  final String? secondaryActionLabel;

  /// Callback for the secondary action. The modal is dismissed automatically
  /// before this fires.
  final VoidCallback? onSecondaryAction;

  const SuccessModal({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.autoDismissDuration,
    this.onDismiss,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    List<List<dynamic>>? icon,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool draggable = true,
    List<double>? snappingConfig,
  }) async {
    final hasSecondary =
        primaryActionLabel != null && secondaryActionLabel != null;
    
    final config = snappingConfig ?? (hasSecondary ? [0.5] : [0.45]);
    await Navigator.of(context).push<void>(
      NonDismissibleGlassSheetRoute<void>(
        draggable: draggable,
        snappingConfig: SheetSnappingConfig(config),
        child: Material(
          type: MaterialType.transparency,
          child: SuccessModal(
            message: message,
            title: title,
            icon: icon,
            autoDismissDuration: autoDismissDuration,
            onDismiss: onDismiss,
            primaryActionLabel: primaryActionLabel,
            onPrimaryAction: onPrimaryAction,
            secondaryActionLabel: secondaryActionLabel,
            onSecondaryAction: onSecondaryAction,
          ),
        ),
      ),
    );

    onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (autoDismissDuration != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(autoDismissDuration!, () {
          if (context.mounted) {
            NavigationService.popScreen();
          }
        });
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ViewUtil.svgPictureAsset(assetName: AssetsUtil.successSvg),
              const SizedBox(height: AppSpacing.md),
              if (title != null) ...[
                AppText(
                  title!,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  colorType: AppTextColor.textInverted,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              AppText(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                colorType: AppTextColor.textMute,
              ),
              const SizedBox(height: AppSpacing.lg),
              ..._buildActions(context),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    // Two-button mode
    if (primaryActionLabel != null && secondaryActionLabel != null) {
      return [
        AppPrimaryButton(
          width: double.infinity,
          onPressed: () {
            NavigationService.popScreen();
            onPrimaryAction?.call();
          },
          child: AppText(
            primaryActionLabel!,
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          width: double.infinity,
          onPressed: () {
            NavigationService.popScreen();
            onSecondaryAction?.call();
          },
          child: AppText(
            secondaryActionLabel!,
            colorType: AppTextColor.textInverted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ];
    }

    // Single primary action (replaces default OK)
    if (primaryActionLabel != null) {
      return [
        AppPrimaryButton(
          width: double.infinity,
          onPressed: () {
            NavigationService.popScreen();
            onPrimaryAction?.call();
          },
          child: AppText(
            primaryActionLabel!,
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ];
    }

    // Default: existing OK button
    return [
      AppTertiaryButton(
        width: double.infinity,
        onPressed: () => NavigationService.popScreen(),
        child: AppText(
          'OK',
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ];
  }
}
