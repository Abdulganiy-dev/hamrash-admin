import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/subjects/subjects_view_model.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// 7.2 · A section's classes with what each takes.
class SubjectClassCard extends StatelessWidget {
  const SubjectClassCard({
    super.key,
    required this.section,
    required this.summaryOf,
    required this.onOpen,
  });

  final SchoolSection section;
  final ClassSubjectsSummary Function(SchoolClass schoolClass) summaryOf;
  final ValueChanged<SchoolClass> onOpen;

  @override
  Widget build(BuildContext context) {
    final classes = section.classes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionCard(
          title: section.name,
          caption:
              classes.length == 1 ? '1 class' : '${classes.length} classes',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            for (final schoolClass in classes)
              _Row(
                name: schoolClass.name,
                summary: summaryOf(schoolClass),
                onTap: () => onOpen(schoolClass),
              ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.name,
    required this.summary,
    required this.onTap,
  });

  final String name;
  final ClassSubjectsSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BouncyButton(
    pressedScale: 0.98,
    onPressed: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 15,
                    color: LightColors.textStrong,
                  ),
                ),
                if (summary.details case final details?) ...[
                  const SizedBox(height: 2),
                  AppText(
                    details,
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
          const SizedBox(width: 12),
          AppText(
            summary.trailing,
            style: AppTypography.label.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color:
                  summary.needsAttention
                      ? LightColors.warningWarningText
                      : LightColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          const AppIcon(
            AppIcons.chevronRight,
            size: 18,
            color: AppPalette.stone400,
          ),
        ],
      ),
    ),
  );
}
