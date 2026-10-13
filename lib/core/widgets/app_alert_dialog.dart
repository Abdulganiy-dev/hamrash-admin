import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_surface.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Centred dialog for decisions that must block everything, e.g. "Session
/// expired". For everyday confirmations prefer a floating sheet — its
/// buttons sit within thumb reach.
///
/// A plain icon, a title, a message and a Cancel / Confirm pair side by
/// side. Returns `true` when confirmed, `false`/`null` when cancelled or
/// dismissed.
///
/// Pass [onConfirm] to run an async action while the dialog stays open with
/// a spinner on the confirm button; throw inside it to keep the dialog open
/// and show an inline error (throw an [AppAlertError] to control the
/// message). Omit it for a plain confirm that closes straight away.
///
/// For an action the user should not skip, set `showCancel: false` and
/// `barrierDismissible: false`, and give [revealCancelAfterAttempts] a small
/// number so someone who genuinely cannot succeed right now still has a way
/// out.
///
/// ```dart
/// final ok = await AppAlertDialog.show(
///   context,
///   icon: LucideIcons.triangleAlert,
///   tone: AppBadgeTone.warning,
///   title: 'Session expired',
///   message: 'Sign in again to keep working. Unsaved attendance is kept on this phone.',
///   cancelLabel: 'Later',
///   confirmLabel: 'Sign in',
/// );
/// ```
class AppAlertDialog extends StatefulWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.tone,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.showCancel = true,
    this.revealCancelAfterAttempts,
    this.onConfirm,
  });

  final String title;
  final String? message;

  /// Shown on its own above the title, in the tone colour.
  final IconData? icon;

  /// Colours the icon. Defaults to [AppBadgeTone.info], or
  /// [AppBadgeTone.error] when [isDestructive].
  final AppBadgeTone? tone;

  final String confirmLabel;
  final String cancelLabel;

  /// Makes the confirm button red, for deleting or withdrawing things.
  final bool isDestructive;

  /// Set false for a required action: the cancel button is hidden and the
  /// back gesture is blocked, so the only way out is a successful
  /// [onConfirm]. Pair it with `barrierDismissible: false`.
  final bool showCancel;

  /// Escape hatch for a required action ([showCancel] false): after this many
  /// failed [onConfirm] attempts the cancel button appears after all.
  ///
  /// The point is to insist without trapping — someone who simply tapped
  /// past the dialog has to engage with it, but someone who cannot succeed
  /// right now (no signal, server down) is not stuck on it indefinitely.
  /// Ignored when [showCancel] is true.
  final int? revealCancelAfterAttempts;

  /// Optional async action run when confirm is tapped. While it runs the
  /// dialog stays open with a spinner; it closes with `true` on success.
  final Future<void> Function()? onConfirm;

  /// Espresso at 36%, the same scrim as sheets.
  static const _scrim = Color(0x5C2A1712);

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    IconData? icon,
    AppBadgeTone? tone,
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
      barrierColor: _scrim,
      builder: (_) => AppAlertDialog(
        title: title,
        message: message,
        icon: icon,
        tone: tone,
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

  /// Always shown for an ordinary dialog; for a required one only once
  /// [AppAlertDialog.revealCancelAfterAttempts] failures have piled up.
  bool get _cancelVisible {
    if (widget.showCancel) return true;
    final threshold = widget.revealCancelAfterAttempts;
    return threshold != null && _failedAttempts >= threshold;
  }

  AppBadgeTone get _tone =>
      widget.tone ??
      (widget.isDestructive ? AppBadgeTone.error : AppBadgeTone.info);

  Future<void> _confirm() async {
    HapticHelpers.vibrate(VibrationType.selection);

    final action = widget.onConfirm;
    if (action == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failedAttempts++;
        _isSubmitting = false;
        _error = e is AppAlertError
            ? e.message
            : 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmLabel = AppText(widget.confirmLabel);
    final confirm = widget.isDestructive
        ? AppDestructiveButton(
            width: double.infinity,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _confirm,
            child: confirmLabel,
          )
        : AppPrimaryButton(
            width: double.infinity,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _confirm,
            child: confirmLabel,
          );

    return PopScope(
      // With no cancel button the dialog is a required action, so the
      // Android back gesture must not dismiss it either.
      canPop: _cancelVisible && !_isSubmitting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPalette.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.overlay,
            ),
            child: AppSurfaceScope(
              surface: AppSurface.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.icon != null) ...[
                    Center(
                      child: _DialogIcon(icon: widget.icon!, tone: _tone),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppText(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.h3.copyWith(
                      color: LightColors.textStrong,
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 6),
                    AppText(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        height: 22 / 15,
                        color: LightColors.textBody,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorLine(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_cancelVisible) ...[
                        Expanded(
                          child: AppSecondaryButton(
                            width: double.infinity,
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: AppText(widget.cancelLabel),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: confirm),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain icon in the tone's base colour, no background.
class _DialogIcon extends StatelessWidget {
  const _DialogIcon({required this.icon, required this.tone});

  final IconData icon;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) => Icon(icon, size: 44, color: tone.base);
}

/// Inline failure from [AppAlertDialog.onConfirm], on a pale red strip.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppBadgeTone.error.mute,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBadgeTone.error.thin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.circleAlert500,
            size: 16,
            color: AppBadgeTone.error.strong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              message,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: AppBadgeTone.error.strong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Throw inside [AppAlertDialog]'s `onConfirm` to keep the dialog open and
/// show [message] as an inline error instead of closing.
class AppAlertError implements Exception {
  const AppAlertError(this.message);
  final String message;

  @override
  String toString() => message;
}
