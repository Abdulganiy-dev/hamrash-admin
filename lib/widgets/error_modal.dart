import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';


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
///   icon: Icons.warning_rounded,
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

  /// Optional icon to display (defaults to error icon)
  final IconData? icon;

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

  /// Show the error modal
  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    IconData? icon,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) async {
    // Haptic feedback
    HapticHelpers.vibrate(VibrationType.medium);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => ErrorModal(
        message: message,
        title: title,
        icon: icon,
        autoDismissDuration: autoDismissDuration,
        onDismiss: onDismiss,
      ),
    );

    // Call onDismiss callback after modal is closed
    onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final errorColor = isLight ? LightColors.errorErrorDefault : DarkColors.errorErrorDefault;
    final errorMuteColor = isLight ? LightColors.errorErrorMute : DarkColors.errorErrorMute;
    final backgroundColor = isLight ? LightColors.backgroundSurfacePrimaryBG : DarkColors.backgroundSurfacePrimaryBG;
    final textColor = isLight ? LightColors.textTextPrimary : DarkColors.textTextPrimary;
    final iconColor = isLight ? LightColors.iconIconPrimary : DarkColors.iconIconPrimary;

    // Auto-dismiss if duration is provided
    if (autoDismissDuration != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(autoDismissDuration!, () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      });
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.2,
      maxChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon and close button
                    Row(
                      children: [
                        // Error icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: errorMuteColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon ?? Icons.error_outline_rounded,
                            color: errorColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null) ...[
                                Text(
                                  title!,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                message,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: textColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: iconColor,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticHelpers.vibrate(VibrationType.light);
                            Navigator.of(context).pop();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

