import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/grading/score_columns_view_model.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_banner.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_bars.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_copy_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/score_column_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_body.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_empty_state.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_text_link.dart';
import 'package:stacked/stacked.dart';

/// 8.26–8.30 · What a subject's score is made of in one section.
class ScoreColumnsScreen extends StatelessWidget {
  const ScoreColumnsScreen({
    super.key,
    required this.school,
    required this.section,
    required this.sections,
  });

  final MemberSchool school;
  final SchoolSection section;
  final List<SchoolSection> sections;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<ScoreColumnsViewModel>.reactive(
        viewModelBuilder: () => ScoreColumnsViewModel(
          school: school,
          section: section,
          sections: sections,
        ),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final actions = _ColumnActions(model);
          return DefaultScaffold(
            title: 'Score columns',
            subtitle: section.name,
            centerTitle: true,
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            body: GradingBody(
              loading: model.loading,
              error: model.error,
              onRetry: model.load,
              stateKey: () => model.inheritsColumns
                  ? 'inherited'
                  : !model.hasColumns
                  ? 'empty'
                  : 'columns',
              content: () => model.inheritsColumns
                  ? _Inherited(model: model, actions: actions)
                  : !model.hasColumns
                  ? _Empty(model: model, actions: actions)
                  : _Columns(model: model, actions: actions),
            ),
          );
        },
      );
}

/// 8.27 · The columns, their shares, and the total.
class _Columns extends StatelessWidget {
  const _Columns({required this.model, required this.actions});

  final ScoreColumnsViewModel model;
  final _ColumnActions actions;

  @override
  Widget build(BuildContext context) => AppRefreshScrollView.children(
    onRefresh: model.refresh,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AppText(
                  GradingNumbers.format(model.grading.totalMarks),
                  colorType: AppTextColor.textStrong,
                  style: AppTypography.heading(
                    40,
                    lineHeight: 48,
                  ).copyWith(letterSpacing: -0.02),
                ),
                const SizedBox(width: 8),
                AppText(
                  'marks in total',
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textBody,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ColumnContributionBar(
              columns: model.columns,
              totalMarks: model.grading.totalMarks,
            ),
            const SizedBox(height: 10),
            AppText(
              'A subject’s percentage is its score out of these '
              '${model.grading.marksLabel}.',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.textBody,
              ),
            ),
            // if (!model.grading.totalIsHundred) ...[
            //   const SizedBox(height: 4),
            //   AppText(
            //     '100 is easiest to read, but any total works.',
            //     style: AppTypography.body.copyWith(
            //       fontSize: 13,
            //       height: 18 / 13,
            //       color: LightColors.textMuted,
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      AppSectionHeader(
        title: 'Columns',
        action: model.canChange
            ? AppSectionAction(
                label: 'Add column',
                icon: AppIcons.plus,
                onPressed: () => actions.add(context),
              )
            : null,
      ),
      // const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          children: [
            for (final (i, column) in model.columns.indexed) ...[
              if (i > 0) const AppDivider(),
              _ColumnRow(
                column: column,
                position: i + 1,
                share: model.grading.shareOf(column),
                onTap: model.canChange
                    ? () => actions.edit(context, column, i)
                    : null,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (model.canChange)
        GradingTextLink(
          icon: AppIcons.copy,
          label: 'Copy columns from another section',
          onPressed: () => actions.copy(context),
        ),
      const SizedBox(height: 24),
    ],
  );
}

class _ColumnRow extends StatelessWidget {
  const _ColumnRow({
    required this.column,
    required this.position,
    required this.share,
    required this.onTap,
  });

  final ScoreColumn column;
  final int position;
  final int share;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 64,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LightColors.categoryTealMute,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppText(
              '$position',
              style: AppTypography.heading(
                16,
                lineHeight: 20,
              ).copyWith(color: LightColors.categoryTealText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  column.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 15,
                    color: LightColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  column.outOf,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: AppText(
              '$share%',
              textAlign: TextAlign.right,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w700,
                color: LightColors.textBody,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (onTap != null)
            const AppIcon(
              AppIcons.chevronRight,
              size: 18,
              color: AppPalette.stone400,
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return BouncyButton(pressedScale: 0.98, onPressed: onTap, child: content);
  }
}

/// 8.26 · No columns in this section yet.
class _Empty extends StatelessWidget {
  const _Empty({required this.model, required this.actions});

  final ScoreColumnsViewModel model;
  final _ColumnActions actions;

  @override
  Widget build(BuildContext context) => GradingEmptyState(
    icon: AppIcons.columns3,
    title: 'No score columns in ${model.section.name} yet',
    subtitle:
        'Add the parts of a subject’s score, like CA 1 out of 20 and an '
        'Exam out of 60. Teachers can’t enter scores until there’s at '
        'least one.',
    actionLabel: model.canChange ? 'Add a column' : null,
    onAction: model.canChange ? () => actions.add(context) : null,
    secondaryLabel: model.canChange ? 'Copy from another section' : null,
    onSecondary: model.canChange ? () => actions.copy(context) : null,
  );
}

/// A section that follows the school's columns. Only reachable defensively;
/// the section page shows this state instead of opening this screen.
class _Inherited extends StatelessWidget {
  const _Inherited({required this.model, required this.actions});

  final ScoreColumnsViewModel model;
  final _ColumnActions actions;

  @override
  Widget build(BuildContext context) => AppRefreshScrollView.children(
    onRefresh: model.refresh,
    children: [
      const GradingBanner(
        tone: GradingBannerTone.plain,
        icon: AppIcons.house,
        title: 'Uses the school’s setup',
        message:
            'These columns were set for the whole school. Give this section '
            'its own copy to change them here.',
      ),
      const SizedBox(height: 24),
      AppSectionHeader(
        title: 'Score columns',
        trailing: AppText(
          model.grading.marksLabel,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          children: [
            for (final (i, column) in model.columns.indexed) ...[
              if (i > 0) const AppDivider(),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        column.name,
                        style: AppTypography.subtitle.copyWith(
                          fontSize: 15,
                          color: LightColors.textStrong,
                        ),
                      ),
                    ),
                    AppText(
                      column.outOf,
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        color: LightColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (model.canChange)
        AppPrimaryButton(
          isLoading: model.saving,
          loadingText: 'Giving ${model.section.name} its own setup…',
          onPressed: () => actions.giveOwnSetup(context),
          child: Text('Give ${model.section.name} its own setup'),
        ),
      const SizedBox(height: 16),
      if (model.canChange)
        GradingTextLink(
          icon: AppIcons.copy,
          label: 'Copy columns from another section',
          onPressed: () => actions.copy(context),
        ),
      const SizedBox(height: 24),
    ],
  );
}

class _ColumnActions {
  const _ColumnActions(this.model);

  final ScoreColumnsViewModel model;

  Future<void> add(BuildContext context) async {
    final done = await _sheet(
      context,
      ScoreColumnSheet(
        grading: model.grading,
        sectionName: model.section.name,
        position: model.columns.length + 1,
        count: model.columns.length,
        onSave: (name, marks, position) =>
            model.addColumn(name, marks, position: position),
      ),
    );
    if (done == true) AppToast.show('Column added');
  }

  Future<void> edit(BuildContext context, ScoreColumn column, int index) async {
    final done = await _sheet(
      context,
      ScoreColumnSheet(
        grading: model.grading,
        sectionName: model.section.name,
        position: index + 1,
        count: model.columns.length,
        column: column,
        onSave: (name, marks, _) => model.saveColumn(column, name, marks),
        onRemove: () => _remove(context, column),
        onMove: (delta) => model.moveColumn(column, delta),
      ),
    );
    if (done == true) AppToast.show('Column saved');
  }

  Future<void> _remove(BuildContext context, ScoreColumn column) async {
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

  Future<void> copy(BuildContext context) async {
    if (model.copySources.isEmpty) {
      AppToast.show('There’s no other section to copy from yet');
      return;
    }
    final done = await _sheet(
      context,
      GradingCopySheet(
        target: model.section,
        sources: model.copySources,
        gradingOf: model.sourceGrading,
        initialColumns: true,
        initialGrades: false,
        onCopy: (from, columns, grades) {
          final source = model.copySources.firstWhere((s) => s.id == from);
          return model.copyFrom(source, columns: columns, grades: grades);
        },
      ),
    );
    if (done == true) {
      AppToast.show('Columns copied into ${model.section.name}');
    }
  }

  Future<void> giveOwnSetup(BuildContext context) async {
    final error = await model.giveOwnSetup();
    if (error != null) {
      AppToast.show(error, type: AppToastType.error);
      return;
    }
    AppToast.show('${model.section.name} has its own setup now');
  }

  static Future<bool?> _sheet(BuildContext context, Widget sheet) =>
      Navigator.of(context).push<bool>(
        AppSheetRoute<bool>(size: AppSheetSize.floating, child: sheet),
      );
}
