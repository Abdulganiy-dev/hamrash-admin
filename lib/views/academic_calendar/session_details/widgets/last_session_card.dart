import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:intl/intl.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// 4.6 · Under the current session: last year's session has ended but isn't
/// closed yet.
class LastSessionCard extends StatelessWidget {
  const LastSessionCard({
    super.key,
    required this.session,
    required this.onClose,
  });

  final AcademicSession session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => AppSectionCard(
    title: 'Last session',
    padding: const EdgeInsets.all(16),
    children: [
      Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppPalette.stone100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AppIcon(
                    AppIcons.calendar,
                    size: 20,
                    color: AppPalette.stone600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        session.name,
                        variant: AppTextVariant.title,
                        colorType: AppTextColor.textStrong,
                      ),
                      AppText(
                        'Ended ${DateFormat('d MMM').format(session.dates.end)} · not closed yet',
                        variant: AppTextVariant.body,
                        colorType: AppTextColor.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppSecondaryButton(
              height: 44,
              onPressed: onClose,
              child: Text('Close ${session.name}'),
            ),
          ],
        ),
    ],
  );
}
