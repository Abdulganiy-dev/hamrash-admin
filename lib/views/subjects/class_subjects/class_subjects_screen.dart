import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/core/bottomSheets/app_action_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/classes/widgets/classes_skeleton.dart';
import 'package:hamrash_admin/views/subjects/class_subjects/class_subjects_view_model.dart';
import 'package:hamrash_admin/views/subjects/class_subjects/widgets/add_subjects_sheet.dart';
import 'package:hamrash_admin/views/subjects/widgets/subject_list_card.dart';
import 'package:hamrash_admin/views/subjects/widgets/subject_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';

/// 7.3–7.5, 7.8 · What one class takes. Pops `true` when something was
/// saved, so the subjects page reloads.
class ClassSubjectsScreen extends StatelessWidget {
  const ClassSubjectsScreen({
    super.key,
    required this.school,
    required this.classId,
  });

  final MemberSchool school;
  final String classId;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<ClassSubjectsViewModel>.reactive(
        viewModelBuilder: () =>
            ClassSubjectsViewModel(school: school, classId: classId),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final schoolClass = model.loading ? null : model.schoolClass;
          final actions = _ClassSubjectsActions(model);
          return DefaultScaffold(
            title: schoolClass?.name ?? 'Subjects',
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            actions: [
              if (model.canChange &&
                  schoolClass != null &&
                  model.arms.isNotEmpty)
                AppNavIconButton(
                  icon: LucideIcons.plus,
                  semanticLabel: 'Add subjects',
                  onPressed: () => actions.addSubjects(context),
                ),
            ],
            body: model.error != null
                ? LoadErrorView(onRetry: model.load)
                : model.loading
                ? const _Loading()
                : schoolClass == null || model.arms.isEmpty
                ? const AppEmptyState(
                    icon: LucideIcons.layers,
                    title: 'No arms to give subjects to',
                    subtitle:
                        'This class was switched off, removed, or has no '
                        'arms yet.',
                  )
                : _Body(model: model, actions: actions),
          );
        },
      );
}

class _Body extends StatelessWidget {
  const _Body({required this.model, required this.actions});

  final ClassSubjectsViewModel model;
  final _ClassSubjectsActions actions;

  /// The "All arms" tab, as the segmented control can't hold null.
  static const _all = '';

  @override
  Widget build(BuildContext context) {
    final tabs = model.tabs;
    final compulsory = model.compulsory;
    final optional = model.optional;
    final canCopy =
        model.canChange &&
        model.arm != null &&
        model.copyTargets.isNotEmpty &&
        (compulsory.isNotEmpty || optional.isNotEmpty);
    final onTap = model.canChange
        ? (Subject subject) => actions.openSubject(context, subject)
        : null;

    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      children: [
        if (tabs.isNotEmpty) ...[
          if (tabs.length <= 4)
            AppSegmentedControl<String>(
              options: [
                for (final id in tabs)
                  AppSegmentOption(
                    value: id ?? _all,
                    label: model.tabLabel(id),
                  ),
              ],
              selected: model.armId ?? _all,
              onChanged: (id) => model.pickArm(id == _all ? null : id),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, id) in tabs.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    AppFilterChip(
                      label: model.tabLabel(id),
                      selected: model.armId == id,
                      onTap: () => model.pickArm(id),
                    ),
                  ],
                ],
              ),
            ),
          if (model.note case final note?) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppText(
                note,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: LightColors.textMuted,
                ),
              ),
            ),
          ],
          if (canCopy) ...[
            const SizedBox(height: 10),
            _CopyLink(
              label: "Copy ${model.arm!.name}'s subjects to another arm",
              onTap: () => actions.copy(context),
            ),
          ],
          const SizedBox(height: 16),
        ],
        if (compulsory.isEmpty && optional.isEmpty)
          AppEmptyState(
            icon: LucideIcons.bookOpen,
            compact: true,
            title: 'No subjects yet',
            subtitle: 'Add the subjects ${model.targetLabel} take.',
            actionLabel: model.canChange ? 'Add subjects' : null,
            onAction: model.canChange
                ? () => actions.addSubjects(context)
                : null,
          ),
        if (compulsory.isNotEmpty) ...[
          AppSectionHeader(
            title: 'Compulsory',
            caption: '${compulsory.length} · every student takes these',
          ),
          const SizedBox(height: 10),
          SubjectListCard(
            subjects: compulsory,
            trailingIcon: LucideIcons.ellipsis,
            onTap: onTap,
          ),
          const SizedBox(height: 20),
        ],
        if (optional.isNotEmpty) ...[
          AppSectionHeader(
            title: 'Optional',
            caption: '${optional.length} · only students who pick them',
          ),
          const SizedBox(height: 10),
          SubjectListCard(
            subjects: optional,
            trailingIcon: LucideIcons.ellipsis,
            onTap: onTap,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CopyLink extends StatelessWidget {
  const _CopyLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: BouncyButton(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.copy,
              size: 16,
              color: LightColors.primaryPrimaryDefault,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AppText(
                label,
                style: AppTypography.button.copyWith(
                  color: LightColors.textBrand,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Opens the sheets and confirmations, and toasts what happened.
class _ClassSubjectsActions {
  const _ClassSubjectsActions(this.model);

  final ClassSubjectsViewModel model;

  /// "SS 1 Science", or the class name when editing all its arms.
  String get _where =>
      model.arm == null ? model.schoolClass!.name : model.targetLabel;

  Future<void> addSubjects(
    BuildContext context, {
    Set<String> preselected = const {},
  }) async {
    final result = await Navigator.of(context).push<AddSubjectsResult>(
      AppSheetRoute<AddSubjectsResult>(
        size: AppSheetSize.floating,
        child: AddSubjectsSheet(model: model, preselected: preselected),
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.create) {
      await _createThenAdd(context, preselected);
      return;
    }
    AppToast.show(
      result.added == 1 ? '1 subject added' : '${result.added} subjects added',
    );
  }

  /// "Not listed? Create a subject": creates it, then reopens the add sheet
  /// with it ticked.
  Future<void> _createThenAdd(BuildContext context, Set<String> picked) async {
    final id = await _subjectSheet(
      context,
      SubjectSheet(
        subtitle: 'Added at the end of the report card',
        nameProblem: model.curriculum.subjectNameProblem,
        codeProblem: model.curriculum.subjectCodeProblem,
        onSave: model.createSubject,
      ),
    );
    if (!context.mounted) return;
    await addSubjects(context, preselected: {...picked, ?id});
  }

  /// 7.4 · A subject's actions.
  Future<void> openSubject(BuildContext context, Subject subject) {
    final compulsory = model.isCompulsory(subject);
    return AppActionSheet.show(
      context,
      title: subject.name,
      subtitle:
          '${compulsory ? 'Compulsory' : 'Optional'} in ${model.targetLabel}',
      groups: [
        [
          AppSheetAction(
            label: compulsory ? 'Make optional' : 'Make compulsory',
            icon: compulsory ? LucideIcons.toggleLeft : LucideIcons.toggleRight,
            onTap: () => _setCompulsory(subject, !compulsory),
          ),
          AppSheetAction(
            label: 'Edit name or code',
            icon: LucideIcons.pencil,
            onTap: () => _edit(context, subject),
          ),
        ],
        [
          AppSheetAction(
            label: 'Remove from $_where',
            icon: LucideIcons.circleMinus,
            isDestructive: true,
            onTap: () => _remove(context, subject),
          ),
        ],
      ],
    );
  }

  Future<void> _setCompulsory(Subject subject, bool compulsory) async {
    final error = await model.setCompulsory(subject, compulsory);
    if (error != null) {
      AppToast.show(error, type: AppToastType.error);
      return;
    }
    AppToast.show(
      '${subject.name} is ${compulsory ? 'compulsory' : 'optional'} now',
    );
  }

  Future<void> _edit(BuildContext context, Subject subject) async {
    final id = await _subjectSheet(
      context,
      SubjectSheet(
        subject: subject,
        subtitle: 'Changes it in every class',
        nameProblem: (name) =>
            model.curriculum.subjectNameProblem(name, except: subject),
        codeProblem: (code) =>
            model.curriculum.subjectCodeProblem(code, except: subject),
        onSave: (name, code) => model.saveSubject(subject, name, code),
      ),
    );
    if (id != null) AppToast.show('Subject saved');
  }

  Future<void> _remove(BuildContext context, Subject subject) async {
    final where = _where;
    final removed = await AppConfirmSheet.show(
      context,
      icon: LucideIcons.circleMinus,
      isDestructive: true,
      title: 'Remove ${subject.name} from $where?',
      message:
          '${model.targetLabel} will no longer take ${subject.name}. It stays '
          "in the school's list of subjects.",
      confirmLabel: 'Remove',
      onConfirm: () => model.removeSubject(subject),
    );
    if (removed == true) AppToast.show('${subject.name} removed from $where');
  }

  /// 7.8 · Copy the current arm's subjects to another arm.
  Future<void> copy(BuildContext context) {
    final from = model.arm!;
    return AppActionSheet.show(
      context,
      title: "Copy ${from.name}'s subjects",
      subtitle: 'To which arm?',
      groups: [
        [
          for (final to in model.copyTargets)
            AppSheetAction(
              label: model.schoolClass!.armLabel(to.name),
              icon: LucideIcons.copy,
              onTap: () => _confirmCopy(context, from, to),
            ),
        ],
      ],
    );
  }

  Future<void> _confirmCopy(
    BuildContext context,
    ClassArm from,
    ClassArm to,
  ) async {
    final copied = await AppConfirmSheet.show(
      context,
      icon: LucideIcons.copy,
      tone: AppBadgeTone.info,
      title: "Copy ${from.name}'s subjects to ${to.name}?",
      message:
          "${to.name} gets the subjects ${from.name} has and it doesn't. "
          'Nothing is removed.',
      confirmLabel: 'Copy subjects',
      onConfirm: () => model.copyTo(to),
    );
    if (copied == true) AppToast.show('Subjects copied to ${to.name}');
  }

  static Future<String?> _subjectSheet(BuildContext context, Widget sheet) =>
      Navigator.of(context).push<String>(
        AppSheetRoute<String>(size: AppSheetSize.floating, child: sheet),
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
