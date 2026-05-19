import 'package:flutter/material.dart';
import 'package:hamrash_admin/assets_util.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hugeicons/hugeicons.dart';
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


  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    List<List<dynamic>>? icon,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
    SheetSnappingConfig? snappingConfig,
  }) async {
    HapticHelpers.vibrate(VibrationType.medium);

    await Navigator.of(context).push<void>(
      StupidSimpleGlassSheetRoute<void>(
        snappingConfig: snappingConfig ?? const SheetSnappingConfig([0.45]),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
  

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
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  colorType: AppTextColor.textInverted,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),

              AppText(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                colorType: AppTextColor.textMute,
              ),

              const SizedBox(height: AppSpacing.lg),

              AppTertiaryButton(
                width: double.infinity,
                onPressed: () => NavigationService.popScreen(),
                child: AppText(
                  'Okay',
                  fontSize: 16,
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

