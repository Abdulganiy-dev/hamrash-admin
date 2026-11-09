import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/grading/grades_screen.dart';
import 'package:hamrash_admin/views/grading/grading_review_screen.dart';
import 'package:hamrash_admin/views/grading/score_columns_screen.dart';
import 'package:hamrash_admin/views/grading/section_grading_view_model.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_banner.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_bars.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_copy_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_status_badge.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_body.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_secondary_button.dart';
import 'package:stacked/stacked.dart';

/// 9.23–9.25 · One section's setup: its two tasks, copying another
/// section's work, or giving it its own copy of the school's setup.
class SectionGradingScreen extends StatelessWidget {
  const SectionGradingScreen({
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
      ViewModelBuilder<SectionGradingViewModel>.reactive(
        viewModelBuilder: () => SectionGradingViewModel(
          school: school,
          section: section,
          sections: sections,
        ),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final actions = _SectionActions(model);
          final grading = model.loading ? null : model.grading;
          return DefaultScaffold(
            title: section.name,
            centerTitle: true,
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            body: GradingBody(
              loading: model.loading,
              error: model.error,
              onRetry: model.load,
              stateKey: () => 'section',
              content: () => AppRefreshScrollView.children(
                onRefresh: model.refresh,
                children: [
                  if (!model.canChange) ...[
                    const GradingBanner(
                      tone: GradingBannerTone.plain,
                      icon: AppIcons.eye,
                      title: 'Read only for you',
                      message:
                          'You can see how this section is graded. '
                          'Only school leaders can change it.',
                    ),
                    const SizedBox(height: 24),
                  ],
                  _Header(section: section, grading: grading!),
                  const SizedBox(height: 24),
                  if (grading.usesSchoolSetup)
                    _InheritedSetup(grading: grading)
                  else
                    _Tasks(model: model, actions: actions),
                  if (!grading.usesSchoolSetup &&
                      !grading.isComplete &&
                      model.canChange) ...[
                    const SizedBox(height: 24),
                    _CopyRow(actions: actions),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
            bottomNavigationBar: model.loading || model.error != null
                ? null
                : grading!.usesSchoolSetup
                ? model.canChange
                      ? _OwnSetupBar(model: model, actions: actions)
                      : null
                : grading.isComplete
                ? _ReviewBar(model: model, actions: actions)
                : null,
          );
        },
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.section, required this.grading});

  final SchoolSection section;
  final SectionGrading grading;

  String get _classes {
    final names = [for (final schoolClass in section.classes) schoolClass.name];
    return _joinNames(names);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grading.usesSchoolSetup) ...[
          Row(
            children: [
              const AppIcon(
                AppIcons.house,
                size: 16,
                color: LightColors.primaryPrimaryText,
              ),
              const SizedBox(width: 6),
              AppText(
                'Uses the school’s setup',
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w700,
                  color: LightColors.primaryPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        AppText(
          grading.usesSchoolSetup
              ? '${section.name} follows the school’s grading'
              : grading.isComplete
              ? '${section.name} is ready'
              : 'Set up ${section.name}',
          colorType: AppTextColor.textStrong,
          style: AppTypography.heading(
            24,
            lineHeight: 32,
          ).copyWith(letterSpacing: -0.01),
        ),
        const SizedBox(height: 6),
        AppText(
          grading.usesSchoolSetup
              ? 'These were set for the whole school before each section had '
                    'its own. To change them for ${section.name} only, give '
                    '${section.name} its own copy of these '
                    '${_count(grading.columns.length, 'column')} and '
                    '${_count(grading.grades.length, 'grade')}.'
              : 'Used by $_classes. '
                    '${grading.isComplete ? 'Teachers can enter scores now.' : 'Do the two parts in any order.'}',
          style: AppTypography.body.copyWith(
            fontSize: 14,
            height: 20 / 14,
            color: LightColors.textBody,
          ),
        ),
      ],
    ),
  );
}

class _Tasks extends StatelessWidget {
  const _Tasks({required this.model, required this.actions});

  final SectionGradingViewModel model;
  final _SectionActions actions;

  @override
  Widget build(BuildContext context) {
    final grading = model.grading;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        children: [
          _TaskRow(
            icon: AppIcons.columns3,
            iconFill: LightColors.categoryTealMute,
            iconColor: LightColors.categoryTealText,
            title: 'Score columns',
            status: grading.hasColumns
                ? GradingStatus.setUp
                : GradingStatus.notSetUp,
            summary: grading.hasColumns
                ? grading.columnsSummary
                : 'What a subject’s score is made of, like CA 1 and Exam',
            onTap: () => actions.openColumns(context),
          ),
          const AppDivider(),
          _TaskRow(
            icon: AppIcons.award,
            iconFill: LightColors.primaryPrimaryMute,
            iconColor: LightColors.primaryPrimaryDefault,
            title: 'Grades',
            status: grading.gradesTile
                ? GradingStatus.setUp
                : GradingStatus.notSetUp,
            summary: grading.hasGrades
                ? grading.gradesSummary
                : 'Which grade each percentage earns, from WAEC or '
                      'Standard',
            onTap: () => actions.openGrades(context),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.icon,
    required this.iconFill,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.summary,
    required this.onTap,
  });

  final IconData icon;
  final Color iconFill;
  final Color iconColor;
  final String title;
  final GradingStatus status;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BouncyButton(
    pressedScale: 0.98,
    onPressed: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        title,
                        style: AppTypography.subtitle.copyWith(
                          fontSize: 15,
                          color: LightColors.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    gradingStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 4),
                AppText(
                  summary,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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

/// 9.25 · The rows the section follows from the school, with nothing of its
/// own to edit yet.
class _InheritedSetup extends StatelessWidget {
  const _InheritedSetup({required this.grading});

  final SectionGrading grading;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(
        title: 'Score columns',
        trailing: AppText(
          grading.marksLabel,
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
            for (final (i, column) in grading.columns.indexed) ...[
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
      AppSectionHeader(
        title: 'Grades',
        trailing: AppText(
          grading.gradeSystem == null
              ? _count(grading.grades.length, 'grade')
              : '${grading.gradeSystem!.label} · '
                    '${_count(grading.grades.length, 'grade')}',
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ),
      const SizedBox(height: 12),
      GradeRangeBar(grading: grading),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppText(
          grading.gradesLine,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: LightColors.textBody,
          ),
        ),
      ),
    ],
  );
}

/// "Save some work" + "Copy from another section".
class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.actions});

  final _SectionActions actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Save some work',
              style: AppTypography.subtitle.copyWith(
                fontSize: 16,
                color: LightColors.textStrong,
              ),
            ),
            const SizedBox(height: 2),
            AppText(
              'Start from a section that’s already set up.',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => actions.copy(context),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.stone100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const AppIcon(
                AppIcons.copy,
                size: 20,
                color: AppPalette.stone700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Copy from another section',
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 15,
                      color: LightColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    'Then change anything. ${actions.model.section.name} stays '
                    'its own.',
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: LightColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const AppIcon(
              AppIcons.chevronRight,
              size: 18,
              color: AppPalette.stone400,
            ),
          ],
        ),
      ),
    ],
  );
}

class _ReviewBar extends StatelessWidget {
  const _ReviewBar({required this.model, required this.actions});

  final SectionGradingViewModel model;
  final _SectionActions actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppPrimaryButton(
        height: 52,
        onPressed: () => actions.review(context),
        child: Text('Review ${model.section.name}'),
      ),
    ),
  );
}

class _OwnSetupBar extends StatelessWidget {
  const _OwnSetupBar({required this.model, required this.actions});

  final SectionGradingViewModel model;
  final _SectionActions actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            height: 52,
            isLoading: model.saving,
            loadingText: 'Giving ${model.section.name} its own setup…',
            onPressed: () => actions.giveOwnSetup(context),
            child: Text('Give ${model.section.name} its own setup'),
          ),
          const SizedBox(height: 16),
          GradingSecondaryButton(
            height: 52,
            icon: AppIcons.copy,
            label: 'Copy from another section instead',
            onPressed: () => actions.copy(context),
          ),
        ],
      ),
    ),
  );
}

class _SectionActions {
  const _SectionActions(this.model);

  final SectionGradingViewModel model;

  Future<void> openColumns(BuildContext context) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: ScoreColumnsScreen(
        school: model.school,
        section: model.section,
        sections: model.sections,
      ),
    );
    if (changed == true) await model.markChanged();
  }

  Future<void> openGrades(BuildContext context) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: GradesScreen(
        school: model.school,
        section: model.section,
        sections: model.sections,
      ),
    );
    if (changed == true) await model.markChanged();
  }

  Future<void> review(BuildContext context) async {
    final done = await NavigationService.animatedNavigation<bool>(
      screen: GradingReviewScreen(
        school: model.school,
        section: model.section,
        sections: model.sections,
      ),
    );
    await model.markChanged();
    if (done == true) NavigationService.popScreen(true);
  }

  Future<void> copy(BuildContext context) async {
    if (model.copySources.isEmpty) {
      AppToast.show('There’s no other section to copy from yet');
      return;
    }
    final done = await Navigator.of(context).push<bool>(
      AppSheetRoute<bool>(
        size: AppSheetSize.floating,
        child: GradingCopySheet(
          target: model.section,
          sources: model.copySources,
          gradingOf: model.sourceGrading,
          onCopy: (from, columns, grades) => model.copyFrom(
            sourceSectionId: from,
            columns: columns,
            grades: grades,
          ),
        ),
      ),
    );
    if (done == true) {
      AppToast.show('Copied into ${model.section.name}');
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
}

String _joinNames(List<String> names) => switch (names.length) {
  0 => 'its classes',
  1 => names.first,
  _ => '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
};

String _count(int count, String noun) => '$count $noun${count == 1 ? '' : 's'}';
