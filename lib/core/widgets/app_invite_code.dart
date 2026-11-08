import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// An eight-character invite code shown as `K7M2-QX9P`, typed straight onto
/// whatever surface it sits on: no card, fill, tint, border or cell behind it.
/// Tapping or long-pressing anywhere copies the raw code (no dash) and shows
/// a short "Copied to clipboard" state — there is no copy button and no toast.
///
/// [code] is the raw code (`K7M2QX9P`); a dash from an older formatted value
/// is ignored. Share the raw code, never the dashes.
///
/// ```dart
/// InviteCodeDisplay(
///   code: rawCode,
///   caption: 'INVITE CODE · TEACHER',
/// )
/// ```
///
/// Leave [caption] null where the page carries its own header row for the
/// label, as the pending invite on the staff page does.
class InviteCodeDisplay extends StatefulWidget {
  const InviteCodeDisplay({super.key, required this.code, this.caption});

  /// Raw 8 characters, e.g. `K7M2QX9P`. Anything but letters and numbers is
  /// dropped, as join does.
  final String code;

  /// Small tracked label above the code, e.g. "INVITE CODE · TEACHER". Upper
  /// cased and centred here.
  final String? caption;

  /// Nunito 700 at 12/16 with 0.12em tracking, stone-600. Pages that put the
  /// label in their own header row (the pending invite) use the same style.
  static TextStyle get labelStyle => AppTypography.label.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: 1.44,
    color: LightColors.textBody,
  );

  @override
  State<InviteCodeDisplay> createState() => _InviteCodeDisplayState();
}

class _InviteCodeDisplayState extends State<InviteCodeDisplay> {
  static const _copiedFor = Duration(milliseconds: 1600);

  /// Nunito 800 at 40/46 with 0.06em tracking.
  static const _codeSize = 40.0;
  static const _codeLineHeight = 46.0;
  static const _codeTracking = 2.4;

  bool _pressed = false;
  bool _copied = false;
  Timer? _copiedTimer;

  String get _raw {
    final clean =
        widget.code.toUpperCase().split('').where((character) {
          final unit = character.codeUnitAt(0);
          return (unit >= 48 && unit <= 57) || (unit >= 65 && unit <= 90);
        }).join();
    return clean.length > 8 ? clean.substring(0, 8) : clean;
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _raw));
    HapticHelpers.vibrate(VibrationType.light);
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(_copiedFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _pressDown(TapDownDetails _) {
    if (!_pressed) setState(() => _pressed = true);
  }

  void _pressUp([TapUpDetails? _]) {
    if (_pressed) setState(() => _pressed = false);
  }

  TextStyle _groupStyle(Color color) => AppTypography.heading(
    _codeSize,
    lineHeight: _codeLineHeight,
  ).copyWith(letterSpacing: _codeTracking, color: color);

  @override
  Widget build(BuildContext context) {
    final groupStyle = _groupStyle(
      _pressed
          ? LightColors.primaryPrimaryPressed
          : LightColors.primaryPrimaryDefault,
    );

    return Semantics(
      button: true,
      label: 'Invite code ${_raw.split('').join(' ')}',
      hint: 'Double tap to copy',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _pressDown,
        onTapUp: _pressUp,
        onTapCancel: _pressUp,
        onTap: _copy,
        onLongPress: _copy,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.caption case final caption?) ...[
                AppText(
                  caption.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: InviteCodeDisplay.labelStyle,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(_group(0, 4), style: groupStyle),
                    const SizedBox(width: AppSpacing.ms),
                    AppText('-', style: _groupStyle(LightColors.textDisabled)),
                    const SizedBox(width: AppSpacing.ms),
                    AppText(_group(4, 8), style: groupStyle),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.ms),
              _helper(),
            ],
          ),
        ),
      ),
    );
  }

  /// The first four characters, or the next four; empty when the code is
  /// shorter, so the row keeps its shape.
  String _group(int start, int end) {
    final raw = _raw;
    if (raw.length <= start) return '';
    return raw.substring(start, raw.length < end ? raw.length : end);
  }

  Widget _helper() {
    if (!_copied) {
      return AppText(
        'Tap or long-press to copy',
        textAlign: TextAlign.center,
        style: AppTypography.label.copyWith(color: LightColors.textBody),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon(
          AppIcons.check,
          size: 14,
          color: LightColors.successSuccessDefault,
        ),
        const SizedBox(width: 6),
        AppText(
          'Copied to clipboard',
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w700,
            color: LightColors.successSuccessText,
          ),
        ),
      ],
    );
  }
}
