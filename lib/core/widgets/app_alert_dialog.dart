import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:flutter/material.dart';

/// A clean, modern, reusable confirmation alert — a centered dialog with an
/// optional icon badge, title, message and a Cancel / Confirm button pair.
///
/// Returns `true` when confirmed, `false`/`null` when cancelled or dismissed.
///
/// Pass [onConfirm] to run an async action while the dialog stays open with a
/// loading spinner on the confirm button; throw inside it to keep the dialog
/// open and surface an inline error (throw an [AppAlertError] to control the
/// message). Omit it for a plain confirm that closes immediately.
///
/// For an action the user should not skip, set `showCancel: false` and
/// `barrierDismissible: false`, and give [revealCancelAfterAttempts] a small
/// number so a user who genuinely cannot succeed right now still has a way out.
///
/// ```dart
/// final ok = await AppAlertDialog.show(
///   context,
///   icon: LucideIcons.userCheck,
///   accentColor: LightColors.primaryPrimaryDefault,
///   title: 'Approve Registration',
///   message: 'The applicant will be notified by email.',
///   confirmLabel: 'Approve',
///   onConfirm: () async {
///     final res = await service.approve(id);
///     if (!res.isSuccess) throw AppAlertError(res.message);
///   },
/// );
/// ```
class AppAlertDialog extends StatefulWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.accentColor,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.showCancel = true,
    this.revealCancelAfterAttempts,
    this.onConfirm,
  });

  final String title;
  final String? message;
  final IconData? icon;

  /// Tints the icon badge and confirm button. Defaults to the brand color, or
  /// the error color when [isDestructive] is true.
  final Color? accentColor;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  /// Set false for a required action: the cancel button is hidden and the back
  /// gesture is blocked, so the only way out is a successful [onConfirm].
  /// Pair it with `barrierDismissible: false`.
  final bool showCancel;

  /// Escape hatch for a required action ([showCancel] false): after this many
  /// failed [onConfirm] attempts the cancel button appears after all.
  ///
  /// The point is to insist without trapping — someone who simply tapped past
  /// the dialog has to engage with it, but someone who genuinely cannot succeed
  /// right now (no signal, server down) is not stuck on it indefinitely.
  /// Ignored when [showCancel] is true.
  final int? revealCancelAfterAttempts;

  /// Optional async action run when confirm is tapped. While it runs the dialog
  /// stays open showing a loading state; it closes with `true` on success.
  final Future<void> Function()? onConfirm;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    IconData? icon,
    Color? accentColor,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    bool barrierDismissible = true,
    bool showCancel = true,
    int? revealCancelAfterAttempts,
    Future<void> Function()? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => AppAlertDialog(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        showCancel: showCancel,
        revealCancelAfterAttempts: revealCancelAfterAttempts,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AppAlertDialog> createState() => _AppAlertDialogState();
}

class _AppAlertDialogState extends State<AppAlertDialog> {
  bool _isSubmitting = false;
  String? _error;
  int _failedAttempts = 0;

  /// Whether the cancel button is currently shown — always for an ordinary
  /// dialog, and for a required one only once [AppAlertDialog
  /// .revealCancelAfterAttempts] failures have piled up.
  bool get _cancelVisible {
    if (widget.showCancel) return true;
    final threshold = widget.revealCancelAfterAttempts;
    return threshold != null && _failedAttempts >= threshold;
  }

  Color get _accent =>
      widget.accentColor ??
      (widget.isDestructive
          ? LightColors.errorErrorDefault
          : LightColors.primaryPrimaryDefault);

  Future<void> _confirm() async {
    HapticHelpers.vibrate(VibrationType.selection);

    final action = widget.onConfirm;
    if (action == null) {
      NavigationService.popScreen(true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await action();
      if (mounted) NavigationService.popScreen(true);
    } on AppAlertError catch (e) {
      if (mounted) {
        setState(() {
          _failedAttempts++;
          _isSubmitting = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failedAttempts++;
          _isSubmitting = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surface = isLight ? Colors.white : DarkColors.backgroundSurfaceLayer;

    return PopScope(
      // With no cancel button the dialog is a required action, so the Android
      // back gesture must not dismiss it either.
      canPop: _cancelVisible && !_isSubmitting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.r24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.icon != null) ...[
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, size: 28, color: _accent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppText(
                  widget.title,
                  colorType: AppTextColor.textInverted,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                if (widget.message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    widget.message!,
                    colorType: AppTextColor.textMute,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    _error!,
                    colorType: AppTextColor.error,
                    fontSize: 13,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    if (_cancelVisible) ...[
                      Expanded(
                        child: AppSecondaryButton(
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting
                              ? null
                              : () => NavigationService.popScreen(false),
                          child: AppText(
                            widget.cancelLabel,
                            colorType: AppTextColor.textInverted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: AppPrimaryButton(
                        onPressed: _isSubmitting ? null : _confirm,
                        isLoading: _isSubmitting,
                        backgroundColor: _accent,
                        child: AppText(
                          widget.confirmLabel,
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Throw inside [AppAlertDialog]'s `onConfirm` to keep the dialog open and show
/// [message] as an inline error instead of closing.
class AppAlertError implements Exception {
  const AppAlertError(this.message);
  final String message;

  @override
  String toString() => message;
}
