import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_action_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/classes/classes_view_model.dart';
import 'package:hamrash_admin/views/classes/widgets/add_arms_sheet.dart';
import 'package:hamrash_admin/views/classes/widgets/arms_banner.dart';
import 'package:hamrash_admin/views/classes/widgets/class_sheet.dart';
import 'package:hamrash_admin/views/classes/widgets/classes_skeleton.dart';
import 'package:hamrash_admin/views/classes/widgets/section_card.dart';
import 'package:hamrash_admin/views/classes/widgets/section_sheet.dart';
import 'package:hamrash_admin/views/classes/widgets/structure_start.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';

/// 6.1–6.4 · Classes and arms, from setup step 3 or the More tab. Pops
/// `true` when something was saved, so the page behind reloads.
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<ClassesViewModel>.reactive(
        viewModelBuilder: () => ClassesViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final starting = model.isEmpty && model.canChange;
          return DefaultScaffold(
            title: 'Classes and arms',
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            actions: [
              if (model.canChange && !model.loading && !model.isEmpty)
                AppNavIconButton(
                  icon: LucideIcons.plus,
                  semanticLabel: 'Add a class or section',
                  onPressed: () => _ClassesActions(model).add(context),
                ),
            ],
            body: model.error != null
                ? LoadErrorView(onRetry: model.load)
                : model.loading
                ? const _Loading()
                : starting
                ? _Start(model: model)
                : model.isEmpty
                ? const AppEmptyState(
                    icon: LucideIcons.layers,
                    title: 'No classes yet',
                    subtitle:
                        "The school's leaders will set up its classes and "
                        'arms.',
                  )
                : _Overview(model: model),
            bottomNavigationBar: starting ? _StartBar(model: model) : null,
          );
        },
      );
}

/// 6.2 · Sections with their classes, after the arms banner.
class _Overview extends StatelessWidget {
  const _Overview({required this.model});

  final ClassesViewModel model;

  @override
  Widget build(BuildContext context) {
    final actions = _ClassesActions(model);
    final withoutArms = model.classesWithoutArms.length;
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      children: [
        if (withoutArms > 0) ...[
          ArmsBanner(
            count: withoutArms,
            onAddArms: model.canChange ? () => actions.addArms(context) : null,
          ),
          const SizedBox(height: 16),
        ],
        for (final (i, section) in model.sections.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          SectionCard(
            section: section,
            onEdit: model.canChange
                ? () => actions.editSection(context, section)
                : null,
            onOpenClass: model.canChange
                ? (schoolClass) => actions.editClass(context, schoolClass)
                : null,
            onAddClass: model.canChange
                ? () => actions.addClass(context, section)
                : null,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Opens the sheets and confirmations, and toasts what happened.
class _ClassesActions {
  const _ClassesActions(this.model);

  final ClassesViewModel model;

  /// The app bar's +: a class in any switched-on section, or a section.
  Future<void> add(BuildContext context) => AppActionSheet.show(
    context,
    title: 'Add',
    groups: [
      [
        for (final section in model.activeSections)
          AppSheetAction(
            label: 'A class in ${section.name}',
            icon: LucideIcons.bookOpen,
            onTap: () => addClass(context, section),
          ),
      ],
      [
        AppSheetAction(
          label: 'A section',
          icon: LucideIcons.layers,
          onTap: () => addSection(context),
        ),
      ],
    ].where((group) => group.isNotEmpty).toList(),
  );

  Future<void> addSection(BuildContext context) async {
    final saved = await _sheet<bool>(context, SectionSheet(model: model));
    if (saved == true) AppToast.show('Section added');
  }

  Future<void> editSection(BuildContext context, SchoolSection section) async {
    final saved = await _sheet<bool>(
      context,
      SectionSheet(
        model: model,
        section: section,
        onToggleActive: () => _toggleSection(context, section),
        onRemove: () => _removeSection(context, section),
      ),
    );
    if (saved == true) AppToast.show('Section saved');
  }

  Future<void> addClass(BuildContext context, SchoolSection section) async {
    final saved = await _sheet<bool>(
      context,
      ClassSheet(model: model, section: section),
    );
    if (saved == true) AppToast.show('Class added');
  }

  Future<void> editClass(BuildContext context, SchoolClass schoolClass) async {
    final saved = await _sheet<bool>(
      context,
      ClassSheet(
        model: model,
        schoolClass: schoolClass,
        onToggleActive: () => _toggleClass(context, schoolClass),
        onRemove: () => _removeClass(context, schoolClass),
      ),
    );
    if (saved == true) AppToast.show('${schoolClass.name} saved');
  }

  Future<void> addArms(BuildContext context) async {
    final added = await _sheet<int>(context, AddArmsSheet(model: model));
    if (added != null) {
      AppToast.show(added == 1 ? '1 arm added' : '$added arms added');
    }
  }

  Future<void> _toggleClass(BuildContext context, SchoolClass schoolClass) =>
      _toggle(
        context,
        name: schoolClass.name,
        isActive: schoolClass.isActive,
        offMessage:
            'It stays in past records, but no new students can join it. '
            'You can switch it back on.',
        onMessage: 'Students can be placed in its arms again.',
        onConfirm: () =>
            model.setClassActive(schoolClass, !schoolClass.isActive),
      );

  Future<void> _toggleSection(BuildContext context, SchoolSection section) =>
      _toggle(
        context,
        name: section.name,
        isActive: section.isActive,
        offMessage:
            'Its classes stay in past records, but no new classes can be '
            'added to it. You can switch it back on.',
        onMessage: 'Classes can be added to it again.',
        onConfirm: () => model.setSectionActive(section, !section.isActive),
      );

  Future<void> _toggle(
    BuildContext context, {
    required String name,
    required bool isActive,
    required String offMessage,
    required String onMessage,
    required Future<void> Function() onConfirm,
  }) async {
    final done = await AppConfirmSheet.show(
      context,
      icon: isActive ? LucideIcons.eyeOff : LucideIcons.eye,
      tone: isActive ? AppBadgeTone.warning : AppBadgeTone.info,
      title: isActive ? 'Switch off $name?' : 'Switch on $name?',
      message: isActive ? offMessage : onMessage,
      confirmLabel: isActive ? 'Switch off' : 'Switch on',
      onConfirm: onConfirm,
    );
    if (done == true) {
      AppToast.show(isActive ? '$name switched off' : '$name switched on');
    }
  }

  Future<void> _removeClass(
    BuildContext context,
    SchoolClass schoolClass,
  ) async {
    final name = schoolClass.name;
    final removed = await AppConfirmSheet.show(
      context,
      icon: LucideIcons.trash2,
      isDestructive: true,
      title: 'Remove $name?',
      message: schoolClass.hasArms
          ? 'The class and its arms will be removed for good, with the '
                'subjects they take.'
          : 'The class will be removed for good.',
      confirmLabel: 'Remove class',
      onConfirm: () => model.deleteClass(schoolClass),
    );
    if (removed == true) AppToast.show('$name removed');
  }

  Future<void> _removeSection(
    BuildContext context,
    SchoolSection section,
  ) async {
    final removed = await AppConfirmSheet.show(
      context,
      icon: LucideIcons.trash2,
      isDestructive: true,
      title: 'Remove ${section.name}?',
      message: 'The section and its grading setup will be removed for good.',
      confirmLabel: 'Remove section',
      onConfirm: () => model.deleteSection(section),
    );
    if (removed == true) AppToast.show('${section.name} removed');
  }

  static Future<T?> _sheet<T>(BuildContext context, Widget sheet) =>
      Navigator.of(
        context,
      ).push<T>(AppSheetRoute<T>(size: AppSheetSize.floating, child: sheet));
}

/// 6.1 · How to start, for a school with no classes.
class _Start extends StatelessWidget {
  const _Start({required this.model});

  final ClassesViewModel model;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Builder(
      builder: (context) => ScaffoldColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),
          StructureStartPicker(value: model.start, onChanged: model.pickStart),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _StartBar extends StatelessWidget {
  const _StartBar({required this.model});

  final ClassesViewModel model;

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
              if (model.start == StructureStart.scratch) {
                await _ClassesActions(model).addSection(context);
              } else if (await model.useStandardStructure()) {
                AppToast.show('Classes added. Now give them arms.');
              }
            },
            child: Text(
              model.start == StructureStart.standard
                  ? 'Use this structure'
                  : 'Add your first section',
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
