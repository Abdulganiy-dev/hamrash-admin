import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_chip_row.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/classes/widgets/classes_skeleton.dart';
import 'package:hamrash_admin/views/grading/grading_view_model.dart';
import 'package:hamrash_admin/views/grading/widgets/grade_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_banner.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_list_card.dart';
import 'package:hamrash_admin/views/grading/widgets/section_scale_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/score_column_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/standard_setup_sheet.dart';
import 'package:stacked/stacked.dart';

/// 9.1–9.11 · Grading, from setup step 4 or the More tab: the score columns a
/// subject's score is made of, and the grade scale (the school default, or a
/// section's own). Leaders change them;
/// everyone else reads. Pops `true` when something was saved, so the page
/// behind reloads.
class GradingScreen extends StatelessWidget {
  const GradingScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<GradingViewModel>.reactive(
        viewModelBuilder: () => GradingViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final actions = _GradingActions(model);
          return DefaultScaffold(
            title: 'Grading',
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            body: AnimatedSectionContent(
              morphHeight: false,
              child: model.error != null
                  ? LoadErrorView(
                      key: const ValueKey('error'),
                      onRetry: model.load,
                    )
                  : model.loading
                  ? const _Loading(key: ValueKey('loading'))
                  : model.showStart
                  ? AppEmptyState(
                      key: const ValueKey('start'),
                      icon: AppIcons.award,
                      title: 'Grading isn’t set up yet',
                      subtitle:
                          'Set what each subject’s score is made of, like CA 1 '
                          'out of 20, and the grades a percentage earns, like '
                          'A from 70. Start from the standard setup and change '
                          'anything you need.',
                      actionLabel: 'Use the standard setup',
                      onAction: () => actions.useStandardSetup(context),
                    )
                  : model.showNotSetUp
                  ? const AppEmptyState(
                      key: ValueKey('not-set-up'),
                      icon: AppIcons.award,
                      title: 'Grading isn’t set up yet',
                      subtitle: 'The school’s leaders will set it up.',
                    )
                  : _Setup(
                      key: const ValueKey('setup'),
                      model: model,
                      actions: actions,
                    ),
            ),
          );
        },
      );
}

/// 9.2, 9.8, 9.9 · The score columns, then the grade scale.
class _Setup extends StatelessWidget {
  const _Setup({super.key, required this.model, required this.actions});

  final GradingViewModel model;
  final _GradingActions actions;

  @override
  Widget build(BuildContext context) {
    final setup = model.setup;
    final canChange = model.canChange;
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      children: [
        if (!canChange) ...[
          const GradingBanner(
            tone: GradingBannerTone.plain,
            title: 'Read only for you',
            message:
                'Only school leaders can change the score columns and the '
                'grade scale. Ask a principal or admin if something needs to '
                'change.',
          ),
          const SizedBox(height: 16),
        ],
        AppSectionHeader(
          title: 'Score columns',
          action: canChange
              ? AppSectionAction(
                  label: 'Add column',
                  icon: AppIcons.plus,
   
                  onPressed: () => actions.addColumn(context),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (!setup.hasColumns)
          GradingBanner(
            tone: GradingBannerTone.warning,
            title: 'No score columns yet',
            message: canChange
                ? 'Without columns there are no marks to add up, so '
                      'teachers can’t enter scores. Add CA 1, CA 2 and '
                      'Exam, or your own.'
                : 'Without columns there are no marks to add up, so '
                      'teachers can’t enter scores yet.',
          )
        else ...[
          GradingListCard(
            rows: [
              for (final (i, column) in setup.columns.indexed)
                GradingRow(
                  tile: '${i + 1}',
                  tone: GradingTileTone.column,
                  title: column.name,
                  details: column.outOf,
                  onTap: canChange
                      ? () => actions.editColumn(context, column)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Total(setup: setup, canChange: canChange),
        ],
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppSectionHeader(
            title: 'Grade scale',
            action: canChange
                ? AppSectionAction(
                    label: 'Add grade',
                    icon: AppIcons.plus,

                    onPressed: () => actions.addGrade(context),
                  )
                : null,
          ),
        ),
        if (model.hasSections) ...[
          const SizedBox(height: 12),
          _ScaleChips(model: model, actions: actions),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppText(
              model.scopeCaption,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 16),
        if (canChange) ...[_Coverage(setup: setup), const SizedBox(height: 16)],
        if (!setup.hasBoundaries && !canChange)
          const GradingBanner(
            tone: GradingBannerTone.plain,
            title: 'No grades yet',
            message: 'The school’s leaders haven’t set the grade scale yet.',
          )
        else if (setup.hasBoundaries)
          GradingListCard(
            rows: [
              for (final boundary in setup.boundaries)
                GradingRow(
                  tile: boundary.grade,
                  tone: boundary.isPass
                      ? GradingTileTone.pass
                      : GradingTileTone.fail,
                  title: setup.rangeOf(boundary),
                  details: setup.detailsOf(boundary),
                  onTap: canChange
                      ? () => actions.editGrade(context, boundary)
                      : null,
                ),
              if (canChange && setup.uncoveredRange != null)
                GradingRow(
                  tile: '?',
                  tone: GradingTileTone.missing,
                  title: setup.uncoveredRange!,
                  details: 'Missing. Add a grade from 0.',
                  onTap: () => actions.addGrade(context, startsAt: '0'),
                ),
            ],
          ),
        if (canChange && !setup.hasZeroBoundary) ...[
          const SizedBox(height: 16),
          AppPrimaryButton(
            size: AppButtonSize.large,
            onPressed: () => actions.addGrade(context, startsAt: '0'),
            child: const Text('Add a grade from 0'),
          ),
        ],
        if (canChange && model.inSectionScope) ...[
          const SizedBox(height: 16),
          _TextLink(
            label: 'Use the school’s scale instead',
            onPressed: () => actions.useSchoolScale(context),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// 9.2, 9.10 · One chip for the school default and one for each section with
/// its own scale; "+ New scale" for leaders while a section has none.
class _ScaleChips extends StatelessWidget {
  const _ScaleChips({required this.model, required this.actions});

  final GradingViewModel model;
  final _GradingActions actions;

  @override
  Widget build(BuildContext context) => AppChipRow(
    inset: 0,
    children: [
      AppFilterChip(
        label: 'School default',
        selected: !model.inSectionScope,
        onTap: () => model.selectScope(null),
      ),
      for (final section in model.ownScaleSections)
        AppFilterChip(
          label: section.name,
          selected: section.id == model.scopeId,
          onTap: () => model.selectScope(section.id),
        ),
      if (model.canAddScale)
        AppFilterChip(
          label: 'New scale',
          suggestion: true,
          onTap: () => actions.addScale(context),
        ),
    ],
  );
}

/// A centred text action under a list, 44 tall.
class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => BouncyButton(
    onPressed: onPressed,
    child: SizedBox(
      height: 44,
      child: Center(
        child: AppText(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w700,
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ),
    ),
  );
}

/// "Total 100 marks." and, for leaders, why the columns needn't add up to
/// 100.
class _Total extends StatelessWidget {
  const _Total({required this.setup, required this.canChange});

  final GradingSetup setup;
  final bool canChange;

  @override
  Widget build(BuildContext context) {
    final body = AppTypography.body.copyWith(
      fontSize: 13,
      height: 18 / 13,
      color: LightColors.textBody,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
        TextSpan(
          style: body,
          children: [
            TextSpan(
              text: 'Total ${GradingNumbers.format(setup.totalMarks)} marks.',
              style: body.copyWith(
                fontWeight: FontWeight.w700,
                color: LightColors.textStrong,
              ),
            ),
            if (canChange)
              const TextSpan(
                text:
                    ' A subject’s percentage is its score out of this total, '
                    'so the columns don’t have to add up to 100.',
              ),
          ],
        ),
      ),
    );
  }
}

/// 9.2 · "Covers 0 to 100", or 9.8 · what the scale leaves out.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.setup});

  final GradingSetup setup;

  @override
  Widget build(BuildContext context) {
    final uncovered = setup.uncoveredRange;
    if (uncovered == null) {
      return const GradingBanner(
        tone: GradingBannerTone.success,
        title: 'Covers 0 to 100',
        message:
            'Every percentage gets one grade. A score takes the highest grade '
            'it reaches.',
      );
    }
    final lowest = setup.hasBoundaries
        ? GradingNumbers.format(setup.boundaries.last.minPercent)
        : null;
    return GradingBanner(
      tone: GradingBannerTone.warning,
      title: 'Not covered: $uncovered',
      message: lowest == null
          ? 'No grades yet. A score gets no grade until one starts at 0, '
                'so report cards can’t be made.'
          : 'Nothing starts at 0. A score under $lowest gets no grade, so '
                'report cards can’t be made for it.',
    );
  }
}

/// Opens the sheets and confirmations, and toasts what happened.
class _GradingActions {
  const _GradingActions(this.model);

  final GradingViewModel model;

  Future<void> useStandardSetup(BuildContext context) async {
    final done = await _sheet(
      context,
      StandardSetupSheet(onConfirm: model.useStandardSetup),
    );
    if (done == true) {
      AppToast.show('Grading set up. Change anything you need.');
    }
  }

  Future<void> addColumn(BuildContext context) async {
    final saved = await _sheet(
      context,
      ScoreColumnSheet(setup: model.setup, onSave: model.addColumn),
    );
    if (saved == true) AppToast.show('Column added');
  }

  Future<void> editColumn(BuildContext context, ScoreColumn column) async {
    final saved = await _sheet(
      context,
      ScoreColumnSheet(
        setup: model.setup,
        column: column,
        onSave: (name, marks) => model.saveColumn(column, name, marks),
        onRemove: () => _removeColumn(context, column),
        onMove: (delta) => model.moveColumn(column, delta),
      ),
    );
    if (saved == true) AppToast.show('${column.name} saved');
  }

  Future<void> _removeColumn(BuildContext context, ScoreColumn column) async {
    if (!context.mounted) return;
    final removed = await AppConfirmSheet.show(
      context,
      icon: AppIcons.trash2,
      isDestructive: true,
      title: 'Remove ${column.name}?',
      message: model.removeColumnMessage(column),
      confirmLabel: 'Remove column',
      onConfirm: () => model.removeColumn(column),
    );
    if (removed == true) AppToast.show('${column.name} removed');
  }

  Future<void> addGrade(BuildContext context, {String? startsAt}) async {
    final saved = await _sheet(
      context,
      GradeSheet(
        setup: model.setup,
        initialPercent: startsAt,
        onSave: (grade, percent, remark, isPass) => model.addGrade(
          grade: grade,
          percent: percent,
          remark: remark,
          isPass: isPass,
        ),
      ),
    );
    if (saved == true) AppToast.show('Grade added');
  }

  Future<void> editGrade(BuildContext context, GradeBoundary boundary) async {
    final saved = await _sheet(
      context,
      GradeSheet(
        setup: model.setup,
        boundary: boundary,
        onSave: (grade, percent, remark, isPass) => model.saveGrade(
          boundary,
          grade: grade,
          percent: percent,
          remark: remark,
          isPass: isPass,
        ),
        onRemove: () => _removeGrade(context, boundary),
      ),
    );
    if (saved == true) AppToast.show('Grade ${boundary.grade} saved');
  }

  Future<void> _removeGrade(
    BuildContext context,
    GradeBoundary boundary,
  ) async {
    if (!context.mounted) return;
    final removed = await AppConfirmSheet.show(
      context,
      icon: AppIcons.trash2,
      isDestructive: true,
      title: 'Remove grade ${boundary.grade}?',
      message:
          'Scores that reached ${boundary.grade} will take the grade below '
          'it. If nothing starts at 0 afterwards, report cards can’t be made.',
      confirmLabel: 'Remove grade',
      onConfirm: () => model.removeGrade(boundary),
    );
    if (removed == true) AppToast.show('Grade ${boundary.grade} removed');
  }

  /// 9.11 · Pick a section and copy the school default into it.
  Future<void> addScale(BuildContext context) async {
    SchoolSection? created;
    final done = await _sheet(
      context,
      SectionScaleSheet(
        sections: model.sectionsWithoutOwnScale,
        ownScaleNames: [for (final s in model.ownScaleSections) s.name],
        onCreate: (section) async {
          final error = await model.createSectionScale(section.id);
          if (error == null) created = section;
          return error;
        },
      ),
    );
    if (done == true && created != null) {
      AppToast.show('${created!.name} scale created');
    }
  }

  /// Deletes the selected section's own grades after asking.
  Future<void> useSchoolScale(BuildContext context) async {
    final section = model.scopeSection;
    if (section == null) return;
    final removed = await AppConfirmSheet.show(
      context,
      icon: AppIcons.trash2,
      isDestructive: true,
      title: 'Use the school’s scale for ${section.name}?',
      message:
          '${section.name}’s own grades will be removed, and it will use the '
          'school default scale again.',
      confirmLabel: 'Remove ${section.name}’s scale',
      onConfirm: model.removeSectionScale,
    );
    if (removed == true) {
      AppToast.show('${section.name} uses the school’s scale');
    }
  }

  static Future<bool?> _sheet(BuildContext context, Widget sheet) =>
      Navigator.of(context).push<bool>(
        AppSheetRoute<bool>(size: AppSheetSize.floating, child: sheet),
      );
}

/// [ClassesSkeleton] where the page's content starts.
class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Builder(
      builder: (context) => ScaffoldColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),
          const ClassesSkeleton(),
        ],
      ),
    ),
  );
}
