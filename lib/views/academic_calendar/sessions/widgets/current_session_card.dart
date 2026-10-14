import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/widgets/session_dates.dart';

/// 4.0 · The current session at the top of the list.
class CurrentSessionCard extends StatelessWidget {
  const CurrentSessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  final AcademicSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weeks = session.terms.fold<int>(
      0,
      (sum, term) => sum + (term.dates.duration.inDays / 7).ceil(),
    );
    final terms = session.terms.length;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${terms == 1 ? '1 TERM' : '$terms TERMS'} · $weeks WEEKS',
                  style: AppTypography.overline.copyWith(
                    color: AppPalette.aubergine500,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  session.name,
                  style: AppTypography.heading(
                    32,
                    lineHeight: 36,
                  ).copyWith(color: AppPalette.stone900),
                ),
                const SizedBox(height: 2),
                AppText(
                  sessionDates(session.dates),
                  variant: AppTextVariant.body,
                  colorType: AppTextColor.textMuted,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppPalette.stone100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AppText(
              'View',
              style: AppTypography.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppPalette.stone900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
