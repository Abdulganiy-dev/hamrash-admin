import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/team/invite_code.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/share_invite.dart';

/// The unused invite on the staff page: an INVITE CODE label with "Never
/// expires", and a white field with the code and two round buttons: copy and
/// share. Copy puts the raw code (no dash) on the clipboard, taps a light
/// haptic and shows the check for a moment; share hands the invite message to
/// the native share sheet through [onShare].
class StaffInviteCodeField extends StatefulWidget {
  const StaffInviteCodeField({super.key, required this.code, this.onShare});

  /// The raw code; shown as `K7M2-QX9P`, copied as `K7M2QX9P`.
  final String code;

  /// Opens the native share sheet. The share button is disabled when null.
  /// It gets the button's rect so iPad can anchor the sheet.
  final void Function(Rect? origin)? onShare;

  @override
  State<StaffInviteCodeField> createState() => _StaffInviteCodeFieldState();
}

class _StaffInviteCodeFieldState extends State<StaffInviteCodeField> {
  static const _copiedFor = Duration(milliseconds: 1600);

  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: InviteCode.rawOf(widget.code)));
    HapticHelpers.vibrate(VibrationType.light);
    AppToast.show('Code copied');
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(_copiedFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = InviteCode.format(widget.code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: AppText(
                'INVITE CODE',
                style: AppTypography.overline.copyWith(
                  height: 14 / 11,
                  color: LightColors.textMuted,
                ),
              ),
            ),
            AppText(
              'Never expires',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: LightColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          key: const ValueKey('invite-code-field'),
          height: 64,
          padding: const EdgeInsets.only(left: AppSpacing.md, right: 14),
          decoration: BoxDecoration(
            color: AppPalette.white,
            borderRadius: AppRadius.brControl,
            border: Border.all(color: AppPalette.stone200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppText(
                      shown,
                      maxLines: 1,
                      style: AppTypography.heading(26, lineHeight: 32).copyWith(
                        letterSpacing: 2.6,
                        color: LightColors.textStrong,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: _copied ? 'Code copied' : 'Copy invite code',
                excludeSemantics: true,
                child: BouncyButton(
                  onPressed: _copy,
                  child: Container(
                    key: const ValueKey('invite-copy-button'),
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppPalette.linen,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppIcon(
                        _copied ? AppIcons.check : AppIcons.copy,
                        size: 17,
                        color: _copied
                            ? LightColors.successSuccessText
                            : LightColors.textBody,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Builder(
                builder: (context) => Semantics(
                  button: true,
                  enabled: widget.onShare != null,
                  label: 'Share invite',
                  excludeSemantics: true,
                  child: BouncyButton(
                    onPressed: widget.onShare == null
                        ? null
                        : () => widget.onShare!(shareOriginOf(context)),
                    child: Container(
                      key: const ValueKey('invite-share-button'),
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppPalette.linen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AppIcon(
                          AppIcons.share,
                          size: 17,
                          color: widget.onShare == null
                              ? LightColors.textDisabled
                              : LightColors.textBody,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
