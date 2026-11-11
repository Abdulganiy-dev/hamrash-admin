import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_person_photo.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_status_pill.dart';
import 'package:url_launcher/url_launcher.dart';

/// The top of the staff page, centred: an 80 circle of initials, the name,
/// "Job title · Staff type", the status pill, then Call, Message and Email as
/// round buttons. Each opens the phone's own app straight away; a missing
/// phone or email greys its buttons out.
class StaffDetailIdentity extends StatelessWidget {
  const StaffDetailIdentity({
    super.key,
    required this.member,
    required this.access,
    required this.meta,
  });

  final StaffMember member;
  final StaffAccess access;

  /// "Bursar · Non-teaching".
  final String meta;

  static const double avatarSize = 80;

  bool get _pending => access == StaffAccess.invitePending;

  bool get _hasLogin =>
      access == StaffAccess.onApp ||
      access == StaffAccess.owner ||
      access == StaffAccess.suspended;

  String get _initials {
    final parts = member.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  ({Color fill, Color foreground}) get _avatarTint {
    if (_pending) {
      return (
        fill: LightColors.primaryPrimaryMute,
        foreground: LightColors.primaryPrimaryText,
      );
    }
    if (_hasLogin) {
      return (
        fill: LightColors.categoryTealMute,
        foreground: LightColors.categoryTealText,
      );
    }
    return (fill: AppPalette.stone100, foreground: AppPalette.stone600);
  }

  String? get _phone {
    final value = member.phone?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _email {
    final value = member.email?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String get _e164 => PhoneFormat.stored(_phone ?? '') ?? _phone!;

  static Future<void> _launch(Uri uri, String failure) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) AppToast.show(failure, type: AppToastType.error);
    } catch (_) {
      AppToast.show(failure, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = _avatarTint;
    final phone = _phone;
    final email = _email;
    final firstName = member.firstNameOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          key: const ValueKey('identity-avatar'),
          dimension: avatarSize,
          child: CustomPaint(
            foregroundPainter: _pending ? const _DashedCircleRing() : null,
            child: AppPersonPhoto(
              url: member.photoUrl,
              size: avatarSize,
              fallback: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.fill,
                  shape: BoxShape.circle,
                ),
                child: AppText(
                  _initials,
                  style: AppTypography.heading(26, lineHeight: 32).copyWith(
                    fontWeight: FontWeight.w800,
                    color: tint.foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AppText(
          member.fullNameWithMiddle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.heading(26, lineHeight: 32).copyWith(
            letterSpacing: -0.39,
            fontWeight: FontWeight.w800,
            color: LightColors.textStrong,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppText(
          meta,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: LightColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        StaffDetailStatusPill(access: access),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionCircle(
              key: const ValueKey('action-call'),
              icon: AppIcons.phone,
              label: 'Call',
              semanticLabel: 'Call $firstName',
              onPressed: phone == null
                  ? null
                  : () => _launch(
                      Uri(scheme: 'tel', path: _e164),
                      "Couldn't open the phone app.",
                    ),
            ),
            const SizedBox(width: 28),
            _ActionCircle(
              key: const ValueKey('action-message'),
              icon: AppIcons.messageCircle,
              label: 'Message',
              semanticLabel: 'Message $firstName',
              onPressed: phone == null
                  ? null
                  : () => _launch(
                      Uri(scheme: 'sms', path: _e164),
                      "Couldn't open Messages.",
                    ),
            ),
            const SizedBox(width: 28),
            _ActionCircle(
              key: const ValueKey('action-email'),
              icon: AppIcons.mail,
              label: 'Email',
              semanticLabel: 'Email $firstName',
              onPressed: email == null
                  ? null
                  : () => _launch(
                      Uri(scheme: 'mailto', path: email),
                      "Couldn't open your email app.",
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A 56 white circle with its label under it, in a 64 wide slot.
class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    enabled: _enabled,
    label: semanticLabel,
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onPressed,
      isDisabled: !_enabled,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _enabled ? AppPalette.white : AppPalette.stone100,
                shape: BoxShape.circle,
                border: _enabled
                    ? Border.all(color: LightColors.strokeColourStrokeCard)
                    : null,
              ),
              child: Center(
                child: AppIcon(
                  icon,
                  size: 22,
                  color: _enabled ? AppPalette.stone700 : AppPalette.stone400,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              label,
              maxLines: 1,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                height: 15 / 12,
                color: _enabled
                    ? LightColors.textBody
                    : LightColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 1.5px dashed ring: an invite that hasn't been claimed yet.
class _DashedCircleRing extends CustomPainter {
  const _DashedCircleRing();

  static const _dash = 4.0;
  static const _gap = 3.0;
  static const _width = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LightColors.primaryPrimaryThin
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width
      ..strokeCap = StrokeCap.round;
    final circle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: (size.width - _width) / 2,
        ),
      );
    for (final metric in circle.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCircleRing oldDelegate) => false;
}
