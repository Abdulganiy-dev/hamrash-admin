import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_option_card.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/classes/classes_screen.dart';
import 'package:hamrash_admin/views/classes/widgets/classes_skeleton.dart';
import 'package:hamrash_admin/views/subjects/class_subjects/class_subjects_screen.dart';
import 'package:hamrash_admin/views/subjects/subjects_view_model.dart';
import 'package:hamrash_admin/views/subjects/widgets/subject_class_card.dart';
import 'package:hamrash_admin/views/subjects/widgets/subject_list_card.dart';
import 'package:hamrash_admin/views/subjects/widgets/subject_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';

/// 7.1–7.2, 7.6–7.7 · Subjects, from setup step 4 or the More tab. Pops
/// `true` when something was saved, so the page behind reloads.
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<SubjectsViewModel>.reactive(
        viewModelBuilder: () => SubjectsViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final starting = model.showStart && model.canChange;
          final actions = _SubjectsActions(model);
          return DefaultScaffold(
            title: 'Subjects',
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            actions: [
              if (model.canChange && model.hasSubjects)
                AppNavIconButton(
                  icon: LucideIcons.plus,
                  semanticLabel: 'Add a subject',
                  onPressed: () => actions.addSubject(context),
                ),
            ],
            body: model.error != null
                ? LoadErrorView(onRetry: model.load)
                : model.loading
                ? const _Loading()
                : model.needsArms
                ? AppEmptyState(
                    icon: LucideIcons.layers,
                    title: 'Add arms first',
                    subtitle:
                        'Subjects are given to each arm, like JSS 1A. Set up '
                        'your classes and their arms, then come back.',
                    actionLabel: model.canChange
                        ? 'Go to classes and arms'
                        : null,
                    onAction: model.canChange
                        ? () => actions.openClasses(context)
                        : null,
                  )
                : starting
                ? _Start(model: model)
                : !model.hasSubjects
                ? const AppEmptyState(
                    icon: LucideIcons.bookOpen,
                    title: 'No subjects yet',
                    subtitle: "The school's leaders will set up its subjects.",
                  )
                : _Overview(model: model, actions: actions),
            bottomNavigationBar: starting
                ? _StartBar(model: model, actions: actions)
                : null,
          );
        },
      );
}

/// 7.2 and 7.6 · By class, or the whole list.
class _Overview extends StatelessWidget {
  const _Overview({required this.model, required this.actions});

  final SubjectsViewModel model;
  final _SubjectsActions actions;

  @override
  Widget build(BuildContext context) {
    final sections = model.sections;
    final subjects = model.visibleSubjects;
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      children: [
        AppSegmentedControl(
          options: const [
            AppSegmentOption(value: SubjectsTab.byClass, label: 'By class'),
            AppSegmentOption(value: SubjectsTab.all, label: 'All subjects'),
          ],
          selected: model.tab,
          onChanged: model.pickTab,
        ),
        const SizedBox(height: 16),
        if (model.tab == SubjectsTab.byClass) ...[
          if (sections.isEmpty)
            const AppEmptyState(
              icon: LucideIcons.layers,
              compact: true,
              title: 'No classes yet',
              subtitle: 'Add classes and arms to give them subjects.',
            ),
          for (final (i, section) in sections.indexed) ...[
            if (i > 0) const SizedBox(height: 16),
            SubjectClassCard(
              section: section,
              summaryOf: model.summaryOf,
              onOpen: (schoolClass) => actions.openClass(context, schoolClass),
            ),
          ],
        ] else ...[
          AppSearchField(hintText: 'Search subjects', onChanged: model.search),
          const SizedBox(height: 16),
          AppSectionHeader(
            title: subjects.length == 1
                ? '1 subject'
                : '${subjects.length} subjects',
            caption: model.query.trim().isEmpty ? 'in report-card order' : null,
          ),
          const SizedBox(height: 10),
          if (subjects.isEmpty)
            AppEmptyState(
              icon: LucideIcons.search,
              compact: true,
              title: 'No subject matches "${model.query.trim()}"',
            )
          else
            SubjectListCard(
              subjects: subjects,
              detailsOf: model.usageOf,
              onTap: model.canChange
                  ? (subject) => actions.editSubject(context, subject)
                  : null,
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Opens the sheets and confirmations, and toasts what happened.
class _SubjectsActions {
  const _SubjectsActions(this.model);

  final SubjectsViewModel model;

  Future<void> openClass(BuildContext context, SchoolClass schoolClass) async {
    if (model.curriculum.armsOf(schoolClass).isEmpty) {
      AppToast.show(
        'Add arms to ${schoolClass.name} first, in Classes and arms',
      );
      return;
    }
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: ClassSubjectsScreen(
        school: model.school,
        classId: schoolClass.id,
      ),
    );
    if (changed == true) await model.refresh().catchError((_) {});
  }

  Future<void> openClasses(BuildContext context) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: ClassesScreen(school: model.school),
    );
    if (changed == true) await model.refresh().catchError((_) {});
  }

  Future<void> addSubject(BuildContext context) async {
    final id = await _sheet(
      context,
      SubjectSheet(
        subtitle: 'Added at the end of the report card',
        nameProblem: model.curriculum.subjectNameProblem,
        codeProblem: model.curriculum.subjectCodeProblem,
        onSave: model.addSubject,
      ),
    );
    if (id != null) AppToast.show('Subject added');
  }

  Future<void> editSubject(BuildContext context, Subject subject) async {
    final id = await _sheet(
      context,
      SubjectSheet(
        subject: subject,
        subtitle: model.placeOf(subject),
        nameProblem: (name) =>
            model.curriculum.subjectNameProblem(name, except: subject),
        codeProblem: (code) =>
            model.curriculum.subjectCodeProblem(code, except: subject),
        onSave: (name, code) async {
          final error = await model.saveSubject(subject, name, code);
          return (id: error == null ? subject.id : null, error: error);
        },
        removeBlockedReason: model.removeBlockedReason(subject),
        onToggleActive: () => _toggle(context, subject),
        onRemove: () => _remove(context, subject),
      ),
    );
    if (id != null) AppToast.show('${subject.name} saved');
  }

  Future<void> _toggle(BuildContext context, Subject subject) async {
    final on = subject.isActive;
    final done = await AppConfirmSheet.show(
      context,
      icon: on ? LucideIcons.eyeOff : LucideIcons.eye,
      tone: on ? AppBadgeTone.warning : AppBadgeTone.info,
      title: on ? 'Switch off ${subject.name}?' : 'Switch on ${subject.name}?',
      message: on
          ? "It stays on past report cards, but it can't be given to classes "
                'or chosen by students. You can switch it back on.'
          : 'It can be given to classes again.',
      confirmLabel: on ? 'Switch off' : 'Switch on',
      onConfirm: () => model.setSubjectActive(subject, !on),
    );
    if (done == true) {
      AppToast.show(
        on ? '${subject.name} switched off' : '${subject.name} switched on',
      );
    }
  }

  Future<void> _remove(BuildContext context, Subject subject) async {
    final removed = await AppConfirmSheet.show(
      context,
      icon: LucideIcons.trash2,
      isDestructive: true,
      title: 'Remove ${subject.name}?',
      message:
          '${subject.name} will be removed for good and taken off every '
          'class that has it.',
      confirmLabel: 'Remove subject',
      onConfirm: () => model.deleteSubject(subject),
    );
    if (removed == true) AppToast.show('${subject.name} removed');
  }

  static Future<String?> _sheet(BuildContext context, Widget sheet) =>
      Navigator.of(context).push<String>(
        AppSheetRoute<String>(size: AppSheetSize.floating, child: sheet),
      );
}

/// 7.1 · How to start, for a school with arms but no subjects.
class _Start extends StatelessWidget {
  const _Start({required this.model});

  final SubjectsViewModel model;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Builder(
      builder: (context) => ScaffoldColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),
          const AppOptionsIntro(
            title: 'Start with the common subjects?',
            body: 'You can add, remove or make any subject optional later.',
          ),
          const SizedBox(height: 20),
          AppOptionCard(
            title: 'Common subjects',
            badge: 'Recommended',
            subtitle:
                '41 Nigerian subjects. Every arm gets the usual list for its '
                'level.',
            value: SubjectsStart.standard,
            groupValue: model.start,
            onChanged: model.pickStart,
            details: const AppOptionSummary(
              rows: [
                ('Nursery', '9 subjects'),
                ('Primary · JSS', '17 subjects, 3 optional'),
                ('SS', '24 subjects, 21 optional'),
              ],
              note: "Arms added later can copy another arm's subjects",
              noteIcon: LucideIcons.copy,
            ),
          ),
          const SizedBox(height: 12),
          AppOptionCard(
            title: 'Start from scratch',
            subtitle:
                'Add your own subjects, then choose what each class takes.',
            value: SubjectsStart.scratch,
            groupValue: model.start,
            onChanged: model.pickStart,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _StartBar extends StatelessWidget {
  const _StartBar({required this.model, required this.actions});

  final SubjectsViewModel model;
  final _SubjectsActions actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (model.startError case final message?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppText(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: LightColors.errorErrorText,
                ),
              ),
            ),
          AppPrimaryButton(
            size: AppButtonSize.large,
            isLoading: model.starting,
            loadingText: 'Setting up…',
            onPressed: () async {
              if (model.start == SubjectsStart.scratch) {
                await actions.addSubject(context);
              } else if (await model.useStandardSubjects()) {
                AppToast.show("Subjects added. Check each class's list.");
              }
            },
            child: Text(
              model.start == SubjectsStart.standard
                  ? 'Use these subjects'
                  : 'Add your first subject',
            ),
          ),
        ],
      ),
    ),
  );
}

/// [ClassesSkeleton] where the page's content starts.
class _Loading extends StatelessWidget {
  const _Loading();

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
