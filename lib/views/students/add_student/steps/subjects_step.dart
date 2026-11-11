import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/step_lead.dart';

/// 9.9 · Step 5, only when the arm offers optional subjects: a flat list
/// to tick (Design System "flat list"), then the compulsory subjects
/// everyone takes. Continue works with none chosen.
class SubjectsStep extends StatelessWidget {
  const SubjectsStep({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final subjects = model.optionalSubjects;
    final compulsory = model.compulsorySubjectNames;
    return StepScroll(
      children: [
        StepLead(
          eyebrow: model.stepEyebrow(AddStudentStep.subjects),
          title: 'Pick optional subjects',
          body: model.subjectsLead,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: 'Optional subjects',
              count: model.chosenCountLabel,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Choosing none is fine. You can set them later.',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < subjects.length; i++) ...[
              if (i > 0)
                const AppDivider(indent: 52, endIndent: 0, onPage: true),
              _SubjectRow(
                subject: subjects[i],
                chosen: model.chosenSubjectIds.contains(subjects[i].subjectId),
                onTap: () => model.toggleSubject(subjects[i].subjectId),
              ),
            ],
          ],
        ),
        if (compulsory.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                title: 'Included for everyone',
                count: model.compulsoryCountLabel,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                compulsory.join(', '),
                style: AppTypography.body.copyWith(
                  height: 22 / 14,
                  color: LightColors.textBody,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Section title with a count on the right. 28 tall.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Row(
      children: [
        Expanded(
          child: AppText(
            title,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w800,
              height: 20 / 16,
              color: LightColors.textStrong,
            ),
          ),
        ),
        AppText(
          count,
          style: AppTypography.label.copyWith(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ],
    ),
  );
}

/// One row of the flat list: code tile, name, checkbox. 64 tall.
class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.chosen,
    required this.onTap,
  });

  final SubjectOffering subject;
  final bool chosen;
  final VoidCallback onTap;

  String get _code {
    final code = subject.code?.trim() ?? '';
    if (code.isNotEmpty) return code.toUpperCase();
    final letters = subject.name.replaceAll(RegExp('[^A-Za-z]'), '');
    return letters
        .substring(0, letters.length < 3 ? letters.length : 3)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: chosen,
    label: subject.name,
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chosen
                    ? LightColors.primaryPrimaryMute
                    : AppPalette.stone100,
                borderRadius: AppRadius.brMd,
              ),
              child: AppText(
                _code,
                maxLines: 1,
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w800,
                  color: chosen
                      ? LightColors.primaryPrimaryText
                      : AppPalette.stone600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: AppText(
                subject.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title.copyWith(
                  height: 22 / 16,
                  fontWeight: chosen ? FontWeight.w700 : FontWeight.w600,
                  color: LightColors.textStrong,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            AppCheckbox(value: chosen),
          ],
        ),
      ),
    ),
  );
}

/// The running total above Continue on this step:
/// "**11 subjects in total** · 9 compulsory + 2 optional".
class SubjectsTotal extends StatelessWidget {
  const SubjectsTotal({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.body.copyWith(color: LightColors.textBody);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          model.subjectTotalLabel,
          style: style.copyWith(
            fontWeight: FontWeight.w800,
            color: LightColors.textStrong,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: AppText(
            model.subjectTotalDetail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
