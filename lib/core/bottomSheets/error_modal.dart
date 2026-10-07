import 'package:hamrash_admin/core/assets_util.dart';
import 'package:hamrash_admin/core/bottomSheets/non_dismissible_glass_sheet_route.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:flutter/material.dart';

import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';


/// A reusable error modal that slides up from the bottom with a nice rounded rectangle design.
/// 
/// Usage example:
/// ```dart
/// // Simple usage
/// ErrorModal.show(
///   context,
///   message: 'Something went wrong. Please try again.',
/// );
/// 
/// // With title and auto-dismiss
/// ErrorModal.show(
///   context,
///   message: 'Network error occurred',
///   title: 'Connection Error',
///   autoDismissDuration: Duration(seconds: 3),
/// );
/// 
/// // With custom icon and dismiss callback
/// ErrorModal.show(
///   context,
///   message: 'Failed to save data',
///   title: 'Save Error',
///   icon: HugeIcons.strokeRoundedAlertCircle,
///   onDismiss: () {
///     print('Modal dismissed');
///   },
/// );
/// ```
class ErrorModal extends StatelessWidget {
  /// The error message to display
  final String message;

  /// Optional title for the error
  final String? title;

  /// Optional HugeIcon to display (defaults to alert circle)
  final List<List<dynamic>>? icon;

  /// Duration before auto-dismissing (null = no auto-dismiss)
  final Duration? autoDismissDuration;

  /// Callback when modal is dismissed
  final VoidCallback? onDismiss;

  const ErrorModal({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.autoDismissDuration,
    this.onDismiss,
  });


  /// Shows the modal using the app's global navigator (no caller [BuildContext]
  /// needed) — safe to call from view models after an async gap.
  static Future<void> showGlobal({
    required String message,
    String? title,
    List<List<dynamic>>? icon,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
    SheetSnappingConfig? snappingConfig,
  }) async {
    final context = ViewUtil.navigatorKey.currentContext;
    if (context == null) return;
    await show(
      context,
      message: message,
      title: title,
      icon: icon,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
      snappingConfig: snappingConfig,
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    List<List<dynamic>>? icon,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
    SheetSnappingConfig? snappingConfig,
  }) async {


    await Navigator.of(context).push<void>(
      NonDismissibleGlassSheetRoute<void>(
        draggable: false,
        snappingConfig: snappingConfig ?? const SheetSnappingConfig([0.4]),
        child: Material(
          type: MaterialType.transparency,
          child: ErrorModal(
            message: message,
            title: title,
            icon: icon,
            autoDismissDuration: autoDismissDuration,
            onDismiss: onDismiss,
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
              ViewUtil.svgPictureAsset(assetName: AssetsUtil.errorSvg),
              const SizedBox(height: AppSpacing.md),
              if (title != null) ...[
                AppText(
                  title!,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  colorType: AppTextColor.textInverted,
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

              AppPrimaryButton(
                width: double.infinity,
                onPressed: () => NavigationService.popScreen(),
                child: AppText(
                  'Okay',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
            
                ),
              ),
              
            ],
          ),
        ),

      ],
    );
  }
}

