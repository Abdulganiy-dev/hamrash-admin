import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_status_pill.dart';

/// The top of the staff page: a 64 circle of initials, the name, the status
/// pill and the job/role line, then the round contact button.
class StaffDetailIdentity extends StatelessWidget {
  const StaffDetailIdentity({
    super.key,
    required this.member,
    required this.access,
    required this.meta,
    required this.onContact,
  });

  final StaffMember member;
  final StaffAccess access;

  /// The job title before they join, the role once they are on the app.
  final String meta;
  final VoidCallback onContact;

  static const double _avatarSize = 64;

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

  ({Color fill, Color foreground, Color ring}) get _avatarTint {
    if (_pending) {
      return (
        fill: LightColors.primaryPrimaryMute,
        foreground: LightColors.primaryPrimaryText,
        ring: AppPalette.aubergine300,
      );
    }
    if (_hasLogin) {
      return (
        fill: LightColors.categoryTealMute,
        foreground: LightColors.categoryTealText,
        ring: LightColors.categoryTealMute,
      );
    }
    return (
      fill: AppPalette.stone100,
      foreground: AppPalette.stone600,
      ring: AppPalette.stone200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tint = _avatarTint;

    return SizedBox(
      height: _avatarSize,
      child: Row(
        children: [
          SizedBox.square(
            key: const ValueKey('identity-avatar'),
            dimension: _avatarSize,
            child: CustomPaint(
              foregroundPainter: _pending ? const _DashedCircleRing() : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.fill,
                  shape: BoxShape.circle,
                  border: _pending ? null : Border.all(color: tint.ring),
                ),
                child: AppText(
                  _initials,
                  style: AppTypography.heading(22, lineHeight: 28).copyWith(
                    fontWeight: FontWeight.w800,
                    color: tint.foreground,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  member.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2.copyWith(
                    height: 30 / 24,
                    color: LightColors.textStrong,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    StaffDetailStatusPill(access: access),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: AppText(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: LightColors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          _ContactIconButton(
            key: const ValueKey('staff-contact-button'),
            firstName: member.firstNameOnly,
            onPressed: onContact,
          ),
        ],
      ),
    );
  }
}

/// 44 round contact button at the right of the identity row.
class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({
    super.key,
    required this.firstName,
    required this.onPressed,
  });

  final String firstName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: 'Contact $firstName',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppPalette.white,
          shape: BoxShape.circle,
          border: Border.all(color: LightColors.strokeColourStrokeCard),
        ),
        child: const Center(
          child: AppSvgIcon(
            AppSvgIcons.phone,
            size: 20,
            color: LightColors.primaryPrimaryDefault,
          ),
        ),
      ),
    ),
  );
}

/// 1px dashed aubergine ring: an invite that hasn't been claimed yet.
class _DashedCircleRing extends CustomPainter {
  const _DashedCircleRing();

  static const _dash = 4.0;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette.aubergine300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final circle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: (size.width - 1) / 2,
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
