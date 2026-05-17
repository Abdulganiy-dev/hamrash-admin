import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/assets_util.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// A reusable warning modal that slides up from the bottom with the same sheet layout as [ErrorModal].
///
/// Usage example:
/// ```dart
/// WarningModal.show(
///   context,
///   message: 'This action cannot be undone.',
/// );
///
/// WarningModal.show(
///   context,
///   title: 'Heads up',
///   subtitle: 'Unsaved changes',
///   message: 'You are about to leave without saving.',
///   autoDismissDuration: Duration(seconds: 4),
/// );
///
/// WarningModal.show(
///   context,
///   message: 'Delete this class?',
///   bottomBody: Row(
///     children: [
///       Expanded(child: AppTertiaryButton(onPressed: pop, child: Text('Cancel'))),
///       Expanded(child: AppPrimaryButton(onPressed: delete, child: Text('Delete'))),
///     ],
///   ),
/// );
/// ```
class WarningModal extends StatelessWidget {
  /// The warning message to display
  final String message;

  /// Optional title
  final String? title;

  /// Optional secondary line shown below [title] and above [message]
  final String? subtitle;

  /// Optional widget below [message] (e.g. custom actions). Falls back to the default "Got it" button when null.
  final Widget? bottomBody;

  /// Optional HugeIcon-style data (reserved for parity with [ErrorModal]; sheet uses [AssetsUtil.warningSvg])
  final List<List<dynamic>>? icon;

  /// Duration before auto-dismissing (null = no auto-dismiss)
  final Duration? autoDismissDuration;

  /// Callback when the sheet route completes (after pop)
  final VoidCallback? onDismiss;

  final List<double>? snappingConfig;

  const WarningModal({
    super.key,
    required this.message,
    this.title,
    this.subtitle,
    this.bottomBody,
    this.icon,
    this.autoDismissDuration,
    this.onDismiss,
    this.snappingConfig,
   
  });

  static Future<R?> show<R>(
    BuildContext context, {
    required String message,
    String? title,
    String? subtitle,
    Widget? bottomBody,
    List<List<dynamic>>? icon,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
    List<double>? snappingConfig,
  }) async {
    HapticHelpers.vibrate(VibrationType.selection);

   final result = await Navigator.of(context).push<R>(
      StupidSimpleGlassSheetRoute<R>(
        snappingConfig: snappingConfig != null ? SheetSnappingConfig(snappingConfig) : const SheetSnappingConfig([0.4]),
        child: Material(
          type: MaterialType.transparency,
          child: WarningModal(
            message: message,
            title: title,
            subtitle: subtitle,
            bottomBody: bottomBody,
            icon: icon,
            autoDismissDuration: autoDismissDuration,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );

    onDismiss?.call();
    return result;
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
              ViewUtil.svgPictureAsset(assetName: AssetsUtil.warningSvg),
              const SizedBox(height: AppSpacing.md),
              if (title != null) ...[
                AppText(
                  title!,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  colorType: AppTextColor.textInverted,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (subtitle != null) ...[
                AppText(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  colorType: AppTextColor.textInverted,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppText(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                colorType: AppTextColor.textMute,
              ),
              const SizedBox(height: AppSpacing.lg),
              bottomBody ?? _defaultBottomButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _defaultBottomButton() {
    return AppTertiaryButton(
      width: double.infinity,
      onPressed: () => NavigationService.popScreen(),
      child: AppText(
        'Got it',
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
