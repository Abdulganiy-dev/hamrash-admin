import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// What happened. Picks the icon, its colours and the default button label.
enum AppResultType {
  success(AppBadgeTone.success, 'Done'),
  error(AppBadgeTone.error, 'Okay'),
  warning(AppBadgeTone.warning, 'Okay');

  const AppResultType(this.tone, this.defaultLabel);

  final AppBadgeTone tone;
  final String defaultLabel;
}

/// Floating sheet that reports how something went: a tinted icon, a title,
/// a message and one or two buttons. Replaces the old success, error and
/// warning modals.
///
/// It must be answered with a button: tapping the scrim or dragging does
/// nothing unless [AppResultSheet.show]'s `dismissible` is true.
///
/// ```dart
/// AppResultSheet.show(
///   context,
///   type: AppResultType.success,
///   title: 'Payment recorded',
///   message: '₦45,000 from Chiamaka Okafor. A receipt has gone to her guardian.',
///   secondaryLabel: 'Record another',
///   onSecondary: viewModel.resetForm,
/// );
/// ```
class AppResultSheet extends StatefulWidget {
  const AppResultSheet({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.body,
    this.autoDismissDuration,
  });

  final AppResultType type;
  final String message;
  final String? title;

  /// Defaults to "Done" for success and "Okay" otherwise.
  final String? primaryLabel;

  /// Runs after the sheet closes.
  final VoidCallback? onPrimary;

  /// Shows a second, text-style button under the primary one.
  final String? secondaryLabel;

  /// Runs after the sheet closes.
  final VoidCallback? onSecondary;

  /// Extra content under the message, e.g. a payment summary.
  final Widget? body;

  /// Closes the sheet on its own after this long.
  final Duration? autoDismissDuration;

  static Future<R?> show<R>(
    BuildContext context, {
    required AppResultType type,
    required String message,
    String? title,
    String? primaryLabel,
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    Widget? body,
    Duration? autoDismissDuration,
    bool dismissible = false,
    VoidCallback? onDismiss,
  }) async {
    final result = await Navigator.of(context).push<R>(
      AppSheetRoute<R>(
        size: AppSheetSize.floating,
        dismissible: dismissible,
        draggable: dismissible,
        child: AppResultSheet(
          type: type,
          message: message,
          title: title,
          primaryLabel: primaryLabel,
          onPrimary: onPrimary,
          secondaryLabel: secondaryLabel,
          onSecondary: onSecondary,
          body: body,
          autoDismissDuration: autoDismissDuration,
        ),
      ),
    );
    onDismiss?.call();
    return result;
  }

  /// [show] through the app's root navigator, so view models can call it
  /// after an async gap without a [BuildContext].
  static Future<void> showGlobal({
    required AppResultType type,
    required String message,
    String? title,
    String? primaryLabel,
    VoidCallback? onPrimary,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) async {
    final context = ViewUtil.navigatorKey.currentContext;
    if (context == null) return;
    await show<void>(
      context,
      type: type,
      message: message,
      title: title,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  @override
  State<AppResultSheet> createState() => _AppResultSheetState();
}

class _AppResultSheetState extends State<AppResultSheet> {
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    final delay = widget.autoDismissDuration;
    if (delay != null) {
      _autoDismiss = Timer(delay, () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  void _closeThen(VoidCallback? action) {
    _autoDismiss?.cancel();
    Navigator.of(context).pop();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    return AppSheet(
      showCloseButton: false,
      showGrabber: false,
      bodyPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      body: Column(
        children: [
          _ResultIcon(type: type),
          const SizedBox(height: 16),
          if (widget.title != null) ...[
            Text(
              widget.title!,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.22,
                color: LightColors.textTextInverted,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              height: 22 / 15,
              color: LightColors.textTextPrimary,
            ),
          ),
          if (widget.body != null) ...[
            const SizedBox(height: 16),
            widget.body!,
          ],
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            width: double.infinity,
            onPressed: () => _closeThen(widget.onPrimary),
            child: Text(widget.primaryLabel ?? type.defaultLabel),
          ),
          if (widget.secondaryLabel != null) ...[
            const SizedBox(height: 8),
            AppButton(
              type: AppButtonType.text,
              width: double.infinity,
              text: widget.secondaryLabel,
              onPressed: () => _closeThen(widget.onSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 72 tinted ring around a 48 solid circle with a white glyph.
class _ResultIcon extends StatelessWidget {
  const _ResultIcon({required this.type});

  final AppResultType type;

  @override
  Widget build(BuildContext context) {
    final tone = type.tone;
    final Widget glyph = switch (type) {
      AppResultType.success => const Icon(
        LucideIcons.check600,
        size: 26,
        color: AppPalette.white,
      ),
      AppResultType.error => const Icon(
        LucideIcons.x600,
        size: 26,
        color: AppPalette.white,
      ),
      AppResultType.warning => Text(
        '!',
        style: AppTypography.h3.copyWith(
          fontSize: 28,
          height: 1,
          fontWeight: FontWeight.w900,
          color: AppPalette.white,
        ),
      ),
    };

    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.mute,
        shape: BoxShape.circle,
        border: Border.all(color: tone.thin),
      ),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tone.base, shape: BoxShape.circle),
        child: glyph,
      ),
    );
  }
}
