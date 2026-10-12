import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Floating sheet that asks before doing something: a tinted icon, a title,
/// a message, then the confirm button with Cancel under it — both within
/// thumb reach. Use this for everyday confirmations; keep [AppAlertDialog]
/// for things that must block everything.
///
/// Returns `true` when confirmed, `false`/`null` when cancelled or dismissed.
///
/// Pass [onConfirm] to run an async action while the sheet stays open with a
/// spinner on the button; throw [AppAlertError] inside it to keep the sheet
/// open and show that message.
///
/// ```dart
/// final ok = await AppConfirmSheet.show(
///   context,
///   icon: LucideIcons.userMinus,
///   isDestructive: true,
///   title: 'Withdraw Chiamaka?',
///   message: "She'll leave JSS 2 Gold and stop getting fee reminders. Her records stay, and you can re-admit her later.",
///   confirmLabel: 'Withdraw student',
///   onConfirm: () => model.withdraw(student),
/// );
/// ```
class AppConfirmSheet extends StatefulWidget {
  const AppConfirmSheet({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.message,
    this.icon,
    this.tone,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
  });

  final String title;
  final String? message;

  /// Shown in a tinted circle above the title.
  final IconData? icon;

  /// Colours the icon. Defaults to [AppBadgeTone.info], or
  /// [AppBadgeTone.error] when [isDestructive].
  final AppBadgeTone? tone;

  final String confirmLabel;
  final String cancelLabel;

  /// Makes the confirm button red.
  final bool isDestructive;

  /// Optional async action run when confirm is tapped; the sheet closes with
  /// `true` once it finishes.
  final Future<void> Function()? onConfirm;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
    IconData? icon,
    AppBadgeTone? tone,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    Future<void> Function()? onConfirm,
  }) {
    return Navigator.of(context).push<bool>(
      AppSheetRoute<bool>(
        size: AppSheetSize.floating,
        child: AppConfirmSheet(
          title: title,
          message: message,
          icon: icon,
          tone: tone,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDestructive: isDestructive,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  @override
  State<AppConfirmSheet> createState() => _AppConfirmSheetState();
}

class _AppConfirmSheetState extends State<AppConfirmSheet> {
  bool _isSubmitting = false;
  String? _error;

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
        _isSubmitting = false;
        _error = e is AppAlertError
            ? e.message
            : 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    final label = Text(widget.confirmLabel);
    final confirm = widget.isDestructive
        ? AppDestructiveButton(
            width: double.infinity,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _confirm,
            child: label,
          )
        : AppPrimaryButton(
            width: double.infinity,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _confirm,
            child: label,
          );

    return PopScope(
      // No closing half way through the action.
      canPop: !_isSubmitting,
      child: AppSheet(
        showCloseButton: false,
        bodyPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.icon != null) ...[
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.mute,
                  shape: BoxShape.circle,
                  border: Border.all(color: tone.thin),
                ),
                child: Icon(widget.icon, size: 22, color: tone.base),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              widget.title,
              style: AppTypography.h3.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.22,
                color: LightColors.textTextInverted,
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.message!,
                style: AppTypography.body.copyWith(
                  fontSize: 15,
                  height: 22 / 15,
                  color: LightColors.textTextPrimary,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.circleAlert500,
                    size: 16,
                    color: AppBadgeTone.error.strong,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
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
            ],
          ],
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            confirm,
            const SizedBox(height: 8),
            AppSecondaryButton(
              width: double.infinity,
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(widget.cancelLabel),
            ),
          ],
        ),
      ),
    );
  }
}
