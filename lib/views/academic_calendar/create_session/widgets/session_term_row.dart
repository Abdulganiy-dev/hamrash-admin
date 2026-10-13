import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_view_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SessionTermRow extends StatelessWidget {
  const SessionTermRow({
    super.key,
    required this.index,
    required this.model,
    required this.onTap,
  });
  final int index;
  final CreateSessionViewModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final term = model.draft.terms[index];
    final current = model.draft.currentTermIndex == index;
    final dates = term.dates;
    final dateLine =
        '${DateFormat('d MMM').format(dates.start)} – ${DateFormat('d MMM').format(dates.end)}';
    final week = ((DateTime.now().difference(dates.start).inDays + 1) / 7)
        .ceil()
        .clamp(1, 99);
    return BouncyButton(
      onPressed: onTap,
      child: Material(
        color: current ? AppPalette.aubergine50 : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current ? AppPalette.aubergine500 : Colors.transparent,
                  shape: BoxShape.circle,
                  border: current
                      ? null
                      : Border.all(color: AppPalette.stone300, width: 1.5),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: current ? Colors.white : AppPalette.stone600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      term.name,
                      color: AppPalette.stone900,
                      fontWeight: FontWeight.w900,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      dateLine,
                      variant: AppTextVariant.body,
                      fontWeight: FontWeight.normal,
                      colorType: current
                          ? AppTextColor.textBody
                          : AppTextColor.textMuted,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (current)
                    AppText(
                      'NOW',
                      color: AppPalette.stone900,
                      fontWeight: FontWeight.w900,
                    ),
                  const SizedBox(height: 2),
                  AppText(
                    current
                        ? 'Week $week of ${(dates.duration.inDays / 7).ceil()}'
                        : AppDateFormat.length(dates),
                    variant: AppTextVariant.body,
                    fontWeight: FontWeight.normal,
                    colorType: current
                        ? AppTextColor.textBody
                        : AppTextColor.textMuted,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: current ? AppPalette.stone900 : AppPalette.stone400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
