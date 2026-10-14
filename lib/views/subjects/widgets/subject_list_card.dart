import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/subjects/widgets/subject_code_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A card of subjects, each with its code chip. Used for the school's whole
/// list (7.6, with a line under each name and a chevron) and a class's
/// compulsory and optional lists (7.3, with "⋯").
class SubjectListCard extends StatelessWidget {
  const SubjectListCard({
    super.key,
    required this.subjects,
    this.detailsOf,
    this.onTap,
    this.trailingIcon = LucideIcons.chevronRight,
  });

  final List<Subject> subjects;

  /// The muted line under each name, e.g. where it's taught.
  final String Function(Subject subject)? detailsOf;

  /// Null for people who can't change subjects.
  final ValueChanged<Subject>? onTap;

  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      children: [
        for (var i = 0; i < subjects.length; i++)
          _Row(
            subject: subjects[i],
            details: detailsOf?.call(subjects[i]),
            showDivider: i < subjects.length - 1,
            trailingIcon: trailingIcon,
            onTap: onTap == null ? null : () => onTap!(subjects[i]),
          ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.subject,
    required this.details,
    required this.showDivider,
    required this.trailingIcon,
    this.onTap,
  });

  final Subject subject;
  final String? details;
  final bool showDivider;
  final IconData trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: BoxConstraints(minHeight: details == null ? 52 : 60),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppPalette.stone100))
            : null,
      ),
      child: Row(
        children: [
          SubjectCodeChip(subject: subject),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 15,
                    fontWeight: details == null
                        ? FontWeight.w600
                        : FontWeight.w700,
                    color: subject.isActive
                        ? LightColors.textStrong
                        : LightColors.textMuted,
                  ),
                ),
                if (details case final text?) ...[
                  const SizedBox(height: 2),
                  AppText(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: LightColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            Icon(trailingIcon, size: 18, color: AppPalette.stone400),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return BouncyButton(pressedScale: 0.98, onPressed: onTap, child: row);
  }
}
