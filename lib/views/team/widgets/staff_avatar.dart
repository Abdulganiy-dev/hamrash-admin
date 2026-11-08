import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// A staff member's initials in a 44 circle, as 8.1 draws them:
///
/// - the owner is solid aubergine with white initials;
/// - an invite nobody has claimed yet is pale aubergine inside a dashed ring;
/// - someone with no login (or a suspended one) is stone;
/// - everyone else takes one of the category tints, picked from their id so
///   the same person keeps the same colour between loads.
class StaffAvatar extends StatelessWidget {
  const StaffAvatar({super.key, required this.person});

  /// Diameter, matching the list row's 44.
  static const double size = 44;

  final StaffMember person;

  StaffAccess get access => person.access;

  /// An invite that hasn't been claimed yet gets the dashed ring.
  bool get pending => access == StaffAccess.invitePending;

  _AvatarTint get _tint => switch (access) {
    StaffAccess.owner => const _AvatarTint(
      fill: LightColors.primaryPrimaryDefault,
      foreground: AppPalette.white,
    ),
    StaffAccess.invitePending => const _AvatarTint(
      fill: LightColors.primaryPrimaryMute,
      foreground: LightColors.primaryPrimaryText,
    ),
    StaffAccess.onApp =>
      _categoryTints[_tintIndex(person.id) % _categoryTints.length],
    StaffAccess.notOnApp || StaffAccess.suspended => const _AvatarTint(
      fill: AppPalette.stone100,
      foreground: AppPalette.stone600,
    ),
  };

  static const _categoryTints = [
    _AvatarTint(
      fill: LightColors.categoryTealMute,
      foreground: LightColors.categoryTealText,
    ),
    _AvatarTint(
      fill: LightColors.categoryHoneyMute,
      foreground: LightColors.categoryHoneyText,
    ),
    _AvatarTint(
      fill: LightColors.categoryTangerineMute,
      foreground: LightColors.categoryTangerineText,
    ),
    _AvatarTint(
      fill: LightColors.categoryChartreuseMute,
      foreground: LightColors.categoryChartreuseText,
    ),
  ];

  /// Stable for a given id: no `hashCode`, which can change between runs.
  static int _tintIndex(String seed) {
    var total = 0;
    for (final unit in seed.codeUnits) {
      total = (total * 31 + unit) & 0x7fffffff;
    }
    return total;
  }

  String get _initials {
    final parts = person.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tint;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        foregroundPainter: pending ? const _DashedAvatarRing() : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: tint.fill, shape: BoxShape.circle),
          child: AppText(
            _initials,
            style: AppTypography.title.copyWith(
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w800,
              color: tint.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarTint {
  const _AvatarTint({required this.fill, required this.foreground});

  final Color fill;
  final Color foreground;
}

/// Dashed aubergine ring around a pending invite's avatar, as on the page.
class _DashedAvatarRing extends CustomPainter {
  const _DashedAvatarRing();

  static const _dash = 4.0;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppPalette.aubergine300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
    final circle =
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2),
            radius: (size.width - 1.5) / 2,
          ),
        );
    for (final metric in circle.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedAvatarRing oldDelegate) => false;
}
