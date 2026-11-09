import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grade_systems.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_icon_label.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/grading/grades_view_model.dart';
import 'package:hamrash_admin/views/grading/widgets/grade_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/grade_system_cards.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_banner.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_bars.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_copy_sheet.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_list_card.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_body.dart';
import 'package:stacked/stacked.dart';

/// 9.32–9.34, 9.40 · One section's grades: choose a system, then edit the
/// ranges. Every save sends the whole new scale.
class GradesScreen extends StatefulWidget {
  const GradesScreen({
    super.key,
    required this.school,
    required this.section,
    required this.sections,
  });

  final MemberSchool school;
  final SchoolSection section;
  final List<SchoolSection> sections;

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  GradeSystem _selected = GradeSystem.standard;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<GradesViewModel>.reactive(
        viewModelBuilder: () => GradesViewModel(
          school: widget.school,
          section: widget.section,
          sections: widget.sections,
        ),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final actions = _GradeActions(model);
          final choosing =
              !model.loading &&
              model.error == null &&
              !model.hasOwnGrades &&
              !model.inheritsGrades;
          return DefaultScaffold(
            title: 'Grades',
            subtitle: widget.section.name,
            centerTitle: true,
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            body: GradingBody(
              loading: model.loading,
              error: model.error,
              onRetry: model.load,
              stateKey: () => choosing
                  ? 'choose'
                  : model.inheritsGrades && !model.hasOwnGrades
                  ? 'inherited'
                  : 'ranges',
              content: () => choosing
                  ? _ChooseSystem(
                      model: model,
                      selected: _selected,
                      onSelected: (system) =>
                          setState(() => _selected = system),
                    )
                  : model.inheritsGrades && !model.hasOwnGrades
                  ? _InheritedGrades(model: model, actions: actions)
                  : _Ranges(model: model, actions: actions),
            ),
            bottomNavigationBar: choosing && model.canChange
                ? _UseSystemBar(
                    system: _selected,
                    onPressed: () => actions.applySystem(context, _selected),
                  )
                : !model.loading &&
                      model.error == null &&
                      !choosing &&
                      !model.inheritsGrades &&
                      !model.grading.gradesTile &&
                      model.canChange
                ? _AddFromZeroBar(actions: actions)
                : null,
          );
        },
      );
}

/// 9.32 · Pick WAEC or Standard as a starting point.
class _ChooseSystem extends StatelessWidget {
  const _ChooseSystem({
    required this.model,
    required this.selected,
    required this.onSelected,
  });

  final GradesViewModel model;
  final GradeSystem selected;
  final ValueChanged<GradeSystem> onSelected;

  @override
  Widget build(BuildContext context) => AppRefreshScrollView.children(
    onRefresh: model.refresh,
    children: [
      if (!model.canChange) ...[
        const GradingBanner(
          tone: GradingBannerTone.plain,
          icon: AppIcons.eye,
          title: 'Read only for you',
          message:
              'You can see the grade systems. Only school leaders can choose '
              'one.',
        ),
        const SizedBox(height: 24),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Which grades should ${model.section.name} use?',
              colorType: AppTextColor.textStrong,
              style: AppTypography.heading(
                24,
                lineHeight: 32,
              ).copyWith(letterSpacing: -0.01),
            ),
            const SizedBox(height: 6),
            AppText(
              'Pick a starting point. Every grade, range and remark stays '
              'editable after.',
              style: AppTypography.body.copyWith(
                fontSize: 14,
                height: 20 / 14,
                color: LightColors.textBody,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GradeSystemChoiceCard(
        system: GradeSystem.waec,
        selected: selected == GradeSystem.waec,
        enabled: model.canChange,
        onTap: () => onSelected(GradeSystem.waec),
      ),
      const SizedBox(height: 16),
      GradeSystemChoiceCard(
        system: GradeSystem.standard,
        selected: selected == GradeSystem.standard,
        enabled: model.canChange,
        onTap: () => onSelected(GradeSystem.standard),
      ),
      const SizedBox(height: 24),
    ],
  );
}

/// 9.33 · The ranges, and what a percentage gets.
class _Ranges extends StatelessWidget {
  const _Ranges({required this.model, required this.actions});

  final GradesViewModel model;
  final _GradeActions actions;

  @override
  Widget build(BuildContext context) {
    final grading = model.grading;
    final gap = grading.uncoveredRange;
    final example = grading.gradeFor(85);
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradeRangeBar(grading: grading),
            const SizedBox(height: 12),
            if (gap == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          AppIcons.circleCheck,
                          size: 18,
                          color: LightColors.successSuccessDefault,
                        ),
                        const SizedBox(width: 8),
                        AppText(
                          'Covers 0 to 100',
                          style: AppTypography.body.copyWith(
                            fontSize: 15,
                            height: 20 / 15,
                            fontWeight: FontWeight.w700,
                            color: LightColors.successSuccessText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      grading.totalIsHundred
                          ? 'Percent of ${model.section.name}’s 100 marks. A '
                                'student with 85 out of 100 has 85%, so gets '
                                'an ${example?.grade ?? '—'}.'
                          : 'Percent of ${model.section.name}’s '
                                '${grading.marksLabel}. A student with 85% '
                                'gets an ${example?.grade ?? '—'}.',
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
                        height: 18 / 13,
                        color: LightColors.textBody,
                      ),
                    ),
                  ],
                ),
              )
            else
              GradingBanner(
                tone: GradingBannerTone.warning,
                title: 'Not covered: $gap',
                message:
                    'Nothing starts at ${gap.split(' ').first}, so a score '
                    'under that gets no grade and ${model.section.name}’s '
                    'report cards can’t be made.',
              ),
          ],
        ),
        const SizedBox(height: 24),
        AppSectionHeader(
          title: 'Grades',
          action: model.canChange
              ? AppSectionAction(
                  label: 'Add grade',
                  icon: AppIcons.plus,
                  onPressed: () => actions.add(context, fromZero: gap != null),
                )
              : null,
        ),
        const SizedBox(height: 12),
        GradingListCard(
          rows: [
            for (final grade in grading.grades)
              GradingRow(
                tile: grade.grade,
                tone: grade.isPass
                    ? GradingTileTone.pass
                    : GradingTileTone.fail,
                title: grading.rangeOf(grade),
                details: grading.detailsOf(grade),
                onTap: model.canChange && gap == null
                    ? () => actions.edit(context, grade)
                    : null,
              ),
          ],
        ),
        if (gap == null) ...[
          const SizedBox(height: 16),
          _TextLinks(model: model, actions: actions),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// A section that follows the school's grades.
class _InheritedGrades extends StatelessWidget {
  const _InheritedGrades({required this.model, required this.actions});

  final GradesViewModel model;
  final _GradeActions actions;

  @override
  Widget build(BuildContext context) => AppRefreshScrollView.children(
    onRefresh: model.refresh,
    children: [
      const GradingBanner(
        tone: GradingBannerTone.plain,
        icon: AppIcons.house,
        title: 'Uses the school’s setup',
        message:
            'These grades were set for the whole school. Give this section '
            'its own copy to change them here.',
      ),
      const SizedBox(height: 24),
      GradeRangeBar(grading: model.grading),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppText(
          model.grading.gradesLine,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: LightColors.textBody,
          ),
        ),
      ),
      const SizedBox(height: 24),
      if (model.canChange) ...[
        AppPrimaryButton(
          onPressed: () => actions.giveOwnGrades(context),
          child: Text('Give ${model.section.name} its own grades'),
        ),
        const SizedBox(height: 16),
        _TextLink(
          icon: AppIcons.copy,
          label: 'Copy grades from another section',
          onPressed: () => actions.copy(context),
        ),
      ],
      const SizedBox(height: 24),
    ],
  );
}

class _TextLinks extends StatelessWidget {
  const _TextLinks({required this.model, required this.actions});

  final GradesViewModel model;
  final _GradeActions actions;

  @override
  Widget build(BuildContext context) {
    if (!model.canChange) return const SizedBox.shrink();
    final current = model.system;
    final targets = current == null ? GradeSystem.values : [current.other];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, target) in targets.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          _TextLink(
            icon: AppIcons.refreshCw,
            label: 'Change to ${target.label} grades',
            onPressed: () => actions.changeSystem(context, target),
          ),
        ],
        const SizedBox(height: 16),
        _TextLink(
          icon: AppIcons.copy,
          label: 'Copy grades from another section',
          onPressed: () => actions.copy(context),
        ),
      ],
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => BouncyButton(
    onPressed: onPressed,
    child: SizedBox(
      height: 44,
      child: Center(
        child: AppIconLabel(
          icon: icon,
          label: label,
          iconColor: LightColors.primaryPrimaryText,
          iconSize: 16,
          gap: 8,
          hugContent: true,
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

class _UseSystemBar extends StatelessWidget {
  const _UseSystemBar({required this.system, required this.onPressed});

  final GradeSystem system;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppPrimaryButton(
        height: 52,
        onPressed: onPressed,
        child: Text('Use ${system.label} grades'),
      ),
    ),
  );
}

class _AddFromZeroBar extends StatelessWidget {
  const _AddFromZeroBar({required this.actions});

  final _GradeActions actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppPrimaryButton(
        height: 52,
        onPressed: () => actions.add(context, fromZero: true),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.plus, size: 16, color: AppPalette.white),
            SizedBox(width: 8),
            Text('Add a grade from 0'),
          ],
        ),
      ),
    ),
  );
}

class _GradeActions {
  const _GradeActions(this.model);

  final GradesViewModel model;

  Future<void> giveOwnGrades(BuildContext context) async {
    final error = await model.giveOwnGrades();
    if (!context.mounted) return;
    if (error != null) {
      AppToast.show(error, type: AppToastType.error);
      return;
    }
    AppToast.show('${model.section.name} has its own grades now');
  }

  Future<void> applySystem(BuildContext context, GradeSystem system) async {
    final error = await model.applySystem(system);
    if (!context.mounted) return;
    if (error != null) {
      AppToast.show(error, type: AppToastType.error);
      return;
    }
    AppToast.show('${model.section.name} now uses ${system.label} grades');
  }

  Future<void> changeSystem(BuildContext context, GradeSystem to) async {
    final current = model.system;
    final changed = await AppConfirmSheet.show(
      context,
      icon: AppIcons.refreshCw,
      tone: AppBadgeTone.info,
      title: 'Replace ${model.section.name}’s grades?',
      message:
          '${model.systemChangeMessage(to)}\n\n'
          '• Only ${model.section.name} changes. Other sections keep their '
          'grades\n'
          '• Published report cards keep their grades. Unpublished results '
          'use the new ones\n'
          '• Every ${to.label} value stays editable after',
      confirmLabel: 'Replace with ${to.label} grades',
      cancelLabel: 'Keep ${current?.label ?? 'current'} grades',
      onConfirm: () async {
        final error = await model.applySystem(to);
        if (error != null) throw AppAlertError(error);
      },
    );
    if (changed == true) {
      AppToast.show('${model.section.name} now uses ${to.label} grades');
    }
  }

  Future<void> add(BuildContext context, {bool fromZero = false}) async {
    final done = await _sheet(
      context,
      GradeSheet(
        grading: model.grading,
        initialFrom: fromZero ? '0' : null,
        onSave: model.saveScale,
      ),
    );
    if (done == true) AppToast.show('Grade added');
  }

  Future<void> edit(BuildContext context, GradeBoundary grade) async {
    final done = await _sheet(
      context,
      GradeSheet(
        grading: model.grading,
        grade: grade,
        onSave: model.saveScale,
        onRemove: () => _remove(context, grade),
      ),
    );
    if (done == true) AppToast.show('Grade ${grade.grade} saved');
  }

  Future<void> _remove(BuildContext context, GradeBoundary grade) async {
    if (!context.mounted) return;
    final removal = model.removalOf(grade);
    final removed = await AppConfirmSheet.show(
      context,
      icon: AppIcons.trash2,
      isDestructive: true,
      title: 'Remove grade ${grade.grade}?',
      message: removal.message,
      confirmLabel: 'Remove grade',
      onConfirm: () => model.removeGrade(grade),
    );
    if (removed == true) AppToast.show('Grade ${grade.grade} removed');
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
        initialColumns: false,
        initialGrades: true,
        onCopy: (from, columns, grades) {
          final source = model.copySources.firstWhere((s) => s.id == from);
          return model.copyFrom(source, columns: columns, grades: grades);
        },
      ),
    );
    if (done == true) {
      AppToast.show('Grades copied into ${model.section.name}');
    }
  }

  static Future<bool?> _sheet(BuildContext context, Widget sheet) =>
      Navigator.of(context).push<bool>(
        AppSheetRoute<bool>(size: AppSheetSize.floating, child: sheet),
      );
}
