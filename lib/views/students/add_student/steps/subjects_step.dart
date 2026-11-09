import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/step_lead.dart';

/// 11.10 · Step 4, only when the arm offers optional subjects: a flat list
/// to tick (Design System "flat list"). Continue works with none chosen.
class SubjectsStep extends StatelessWidget {
  const SubjectsStep({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final subjects = model.optionalSubjects;
    final compulsory = model.compulsoryCount;
    return StepScroll(
      gap: AppSpacing.ml,
      children: [
        StepLead(
          eyebrow: model.stepEyebrow(AddStudentStep.subjects),
          title: 'Pick optional subjects',
          body:
              '${model.armLabel} offers these as choices. Tap the ones they '
              'will study.',
        ),
        if (compulsory > 0)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: AppIcon(
                  AppIcons.circleCheck,
                  size: 18,
                  color: AppPalette.stone500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.body.copyWith(
                      color: LightColors.textBody,
                    ),
                    children: [
                      TextSpan(
                        text: compulsory == 1
                            ? '1 compulsory subject is included.'
                            : '$compulsory compulsory subjects are included.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: LightColors.textStrong,
                        ),
                      ),
                      const TextSpan(text: ' Everyone in the arm takes them.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      'Optional subjects',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 20 / 16,
                        color: LightColors.textStrong,
                      ),
                    ),
                  ),
                  AppText(
                    '${model.chosenSubjectIds.length} chosen',
                    style: AppTypography.label.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w700,
                      color: LightColors.primaryPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < subjects.length; i++) ...[
              if (i > 0)
                const AppDivider(indent: 52, endIndent: 0, onPage: true),
              _SubjectRow(
                subject: subjects[i],
                chosen: model.chosenSubjectIds.contains(subjects[i].subjectId),
                onTap: () => model.toggleSubject(subjects[i].subjectId),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'Not sure yet? Continue without picking. You can set them later.',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One row of the flat list: code tile, name, check circle. 64 tall.
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
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chosen ? LightColors.primaryPrimaryDefault : null,
                border: chosen
                    ? null
                    : Border.all(color: AppPalette.stone300, width: 1.5),
              ),
              child: chosen
                  ? const AppIcon(
                      AppIcons.check,
                      size: 14,
                      color: AppPalette.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}
