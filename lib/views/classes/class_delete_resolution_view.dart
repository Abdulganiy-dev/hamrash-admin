import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_delete_preflight.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/viewModel/class_delete_resolution_view_model.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/delete_resolution/delete_resolution_all_clear_card.dart';
import 'package:hamrash_admin/widgets/delete_resolution/delete_resolution_deactivate_card.dart';
import 'package:hamrash_admin/widgets/delete_resolution/delete_resolution_delete_button.dart';
import 'package:hamrash_admin/widgets/delete_resolution/delete_resolution_dialogs.dart';
import 'package:hamrash_admin/widgets/delete_resolution/delete_resolution_headline.dart';
import 'package:hamrash_admin/widgets/delete_resolution/delete_resolution_list_rows.dart';
import 'package:hamrash_admin/widgets/delete_resolution/delete_resolution_section_shell.dart';
import 'package:hamrash_admin/widgets/haptic_list_tile.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

/// Full-screen workflow for hard-deleting a class with dependencies.
/// Pops with a [ClassDeleteResolutionResult].
class ClassDeleteResolutionView extends StatefulWidget {
  const ClassDeleteResolutionView({super.key, required this.classToDelete});

  final ClassModel classToDelete;

  @override
  State<ClassDeleteResolutionView> createState() =>
      _ClassDeleteResolutionViewState();
}

class _ClassDeleteResolutionViewState extends State<ClassDeleteResolutionView> {
  late ClassDeleteResolutionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ClassDeleteResolutionViewModel>.reactive(
      viewModelBuilder: () =>
          ClassDeleteResolutionViewModel(target: widget.classToDelete),
      onViewModelReady: (m) {
        viewModel = m;
        m.init();
      },
      builder: (context, m, _) {
        final preflight = m.preflight;
        return DefaultScaffold(
          title: 'Resolve dependencies',
          showBackButton: true,
          busy: m.busy,
          appBarType: DefaultScaffoldAppBarType.standard,
          body: Builder(
            builder: (ctx) {
              if (preflight == null) {
                return const SizedBox.shrink();
              }
              return SingleChildScrollView(
                child: ScaffoldColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: ScaffoldInsets.of(ctx).bodyTopInset + 15),
                    DeleteResolutionHeadline(
                      entityDisplayName: widget.classToDelete.displayName,
                      clearanceMessage:
                          'Take care of the items below. The class can be '
                          'deleted once every section is cleared.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (preflight.students.isNotEmpty) ...[
                      _StudentsSection(vm: m),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (preflight.homeroomTeachers.isNotEmpty) ...[
                      _HomeroomSection(vm: m),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (!preflight.hasBlockers) ...[
                      const DeleteResolutionAllClearCard(
                        readyMessage:
                            'No more blockers. The class can be deleted now.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _AutoRemovedFootnote(preflight: preflight),
                    const SizedBox(height: AppSpacing.xl),
                    _DeactivateCard(vm: m),
                    const SizedBox(height: AppSpacing.md),
                    _DeleteButton(vm: m),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AutoRemovedFootnote extends StatelessWidget {
  const _AutoRemovedFootnote({required this.preflight});
  final ClassDeletePreflight preflight;

  @override
  Widget build(BuildContext context) {
    final curriculum = preflight.autoRemovedCurriculumSubjects;
    final assignments = preflight.autoRemovedTeacherAssignments;
    if (curriculum == 0 && assignments == 0) {
      return const SizedBox.shrink();
    }
    final parts = <String>[
      if (curriculum > 0)
        '$curriculum curriculum link${curriculum == 1 ? '' : 's'}',
      if (assignments > 0)
        '$assignments teacher assignment${assignments == 1 ? '' : 's'}',
    ];
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            size: 18,
            strokeWidth: 1.8,
            color: LightColors.textTextMute,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText(
              '${parts.join(' and ')} will be removed automatically on delete.',
              colorType: AppTextColor.textMute,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsSection extends StatelessWidget {
  const _StudentsSection({required this.vm});
  final ClassDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final students = vm.preflight!.students;
    return DeleteResolutionSectionShell(
      icon: HugeIcons.strokeRoundedStudent,
      iconColor: Colors.blueAccent,
      title: 'Enrolled students',
      count: students.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeleteResolutionItemList(
            children: [
              for (final s in students)
                DeleteResolutionPersonRow(
                  avatarUrl: s.avatarUrl ?? '',
                  title: s.fullName,
                  subtitle: s.admissionNumber,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  onPressed: () => _bulkMove(context, vm, students),
                  child: const Text('Move all to…'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTertiaryButton(
                  onPressed: () => _bulkUnassign(context, vm, students),
                  child: const Text('Unassign all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _bulkMove(
    BuildContext context,
    ClassDeleteResolutionViewModel vm,
    List<ClassDeleteStudent> students,
  ) async {
    if (vm.moveTargets.isEmpty) {
      await showDeleteResolutionInfoDialog(
        context,
        title: 'No other classes',
        message:
            'There\'s no other class to move these students into. Try '
            '"Unassign all" instead, or create another class first.',
      );
      return;
    }
    final target = await ListBottomSheet.show<ClassModel, ClassModel>(
      context: context,
      title:
          'Move ${students.length} student${students.length == 1 ? '' : 's'} to…',
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedSchool,
        size: 30,
        strokeWidth: 2,
        color: Colors.blueAccent,
      ),
      items: vm.moveTargets,
      itemBuilder: (ctx, cls, _) => HapticListTile(
        title: AppText(
          cls.displayName,
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w500,
        ),
        onTap: () => Navigator.of(ctx).pop(cls),
      ),
    );
    if (target == null || target.id == null || !context.mounted) return;

    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Move students?',
      message:
          'Moving these students to ${target.displayName} will clear their '
          'current subject enrollments. You can re-enroll them after.',
      confirmLabel: 'Move',
    );
    if (!confirmed) return;

    await vm.moveStudents(
      studentIds: students.map((s) => s.id).toList(),
      newClassId: target.id!,
    );
  }

  Future<void> _bulkUnassign(
    BuildContext context,
    ClassDeleteResolutionViewModel vm,
    List<ClassDeleteStudent> students,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title:
          'Unassign ${students.length} student${students.length == 1 ? '' : 's'}?',
      message:
          'They\'ll have no class until you reassign them. Their subject '
          'enrollments will also be cleared.',
      confirmLabel: 'Unassign',
      destructive: true,
    );
    if (!confirmed) return;
    await vm.unassignStudents(students.map((s) => s.id).toList());
  }
}

class _HomeroomSection extends StatelessWidget {
  const _HomeroomSection({required this.vm});
  final ClassDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final teachers = vm.preflight!.homeroomTeachers;
    return DeleteResolutionSectionShell(
      icon: HugeIcons.strokeRoundedTeacher,
      iconColor: Colors.orange,
      title: 'Homeroom assignment',
      count: teachers.length,
      child: DeleteResolutionItemList(
        children: [
          for (final t in teachers)
            DeleteResolutionPersonRow(
              avatarUrl: t.avatarUrl ?? '',
              title: t.fullName,
              subtitle: _roleLabel(t.homeroomRole),
              onRemove: () => _confirmClear(context, vm, t),
            ),
        ],
      ),
    );
  }

  static String _roleLabel(String? role) {
    switch (role) {
      case 'class_teacher':
        return 'Main teacher';
      case 'assistant_class_teacher':
        return 'Assistant teacher';
      default:
        return 'Homeroom';
    }
  }

  Future<void> _confirmClear(
    BuildContext context,
    ClassDeleteResolutionViewModel vm,
    ClassDeleteHomeroomTeacher t,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Clear homeroom?',
      message:
          '${t.fullName} will no longer be the homeroom for this class. '
          'They\'ll keep their teacher profile.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed) return;
    await vm.clearHomeroom(t);
  }
}

class _DeactivateCard extends StatelessWidget {
  const _DeactivateCard({required this.vm});
  final ClassDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DeleteResolutionDeactivateCard(
      description:
          'Hides the class from active lists without removing any students, '
          'teachers, or history.',
      buttonLabel: 'Deactivate this class',
      onPressed: () => _confirm(context, vm),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    ClassDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Deactivate class?',
      message:
          '${vm.target.displayName} will be hidden from active class lists. '
          'You can reactivate it later. Nothing else is removed.',
      confirmLabel: 'Deactivate',
    );
    if (!confirmed || !context.mounted) return;
    final result = await vm.finalizeDeactivate();
    if (!context.mounted) return;
    if (result == ClassDeleteResolutionResult.deactivated) {
      Navigator.of(context).pop(result);
    }
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.vm});
  final ClassDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DeleteResolutionDeleteButton(
      entityDisplayName: vm.target.displayName,
      enabled: vm.canDelete,
      onPressed: () => _confirm(context, vm),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    ClassDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Delete class?',
      message:
          '${vm.target.displayName} will be permanently removed. This cannot '
          'be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await vm.finalizeDelete();
    if (!context.mounted) return;
    if (result == ClassDeleteResolutionResult.deleted) {
      Navigator.of(context).pop(result);
    }
  }
}
