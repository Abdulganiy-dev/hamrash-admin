import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/subject_delete_preflight.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/subject_delete_resolution_view_model.dart';
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
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

/// Full-screen workflow for hard-deleting a subject with dependencies.
class SubjectDeleteResolutionView extends StatefulWidget {
  const SubjectDeleteResolutionView({super.key, required this.subjectToDelete});

  final SubjectModel subjectToDelete;

  @override
  State<SubjectDeleteResolutionView> createState() =>
      _SubjectDeleteResolutionViewState();
}

class _SubjectDeleteResolutionViewState
    extends State<SubjectDeleteResolutionView> {
  late SubjectDeleteResolutionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SubjectDeleteResolutionViewModel>.reactive(
      viewModelBuilder: () =>
          SubjectDeleteResolutionViewModel(target: widget.subjectToDelete),
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
                      entityDisplayName: widget.subjectToDelete.name,
                      clearanceMessage:
                          'Take care of the items below. The subject can be '
                          'deleted once every section is cleared.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (preflight.classes.isNotEmpty) ...[
                      _ClassesSection(vm: m),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (preflight.teacherAssignments.isNotEmpty) ...[
                      _TeacherAssignmentsSection(vm: m),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (preflight.enrolledStudentsCount > 0) ...[
                      _StudentsSection(vm: m),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (!preflight.hasBlockers) ...[
                      const DeleteResolutionAllClearCard(
                        readyMessage:
                            'No more blockers. The subject can be deleted now.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
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

class _ClassesSection extends StatelessWidget {
  const _ClassesSection({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final classes = vm.preflight!.classes;
    return DeleteResolutionSectionShell(
      icon: HugeIcons.strokeRoundedSchool,
      iconColor: Colors.blueAccent,
      title: 'Classes using this subject',
      count: classes.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeleteResolutionItemList(
            children: [
              for (final c in classes)
                DeleteResolutionTextActionRow(
                  title: c.displayName,
                  onRemove: () => _confirmRemoveOne(context, vm, c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            width: double.infinity,
            onPressed: () => _confirmRemoveAll(context, vm, classes.length),
            child: Text(
              'Remove from all ${classes.length} class${classes.length == 1 ? '' : 'es'}',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveOne(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
    SubjectDeleteClass entry,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Remove from curriculum?',
      message:
          '${vm.target.name} will no longer be part of ${entry.displayName}\'s '
          'curriculum.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    await vm.removeFromOneClass(entry);
  }

  Future<void> _confirmRemoveAll(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
    int count,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Remove from $count class${count == 1 ? '' : 'es'}?',
      message: '${vm.target.name} will be removed from every class curriculum.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    await vm.removeFromAllClasses();
  }
}

class _TeacherAssignmentsSection extends StatelessWidget {
  const _TeacherAssignmentsSection({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final rows = vm.preflight!.teacherAssignments;
    return DeleteResolutionSectionShell(
      icon: HugeIcons.strokeRoundedTeacher,
      iconColor: Colors.orange,
      title: 'Teacher assignments',
      count: rows.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeleteResolutionItemList(
            children: [
              for (final r in rows)
                DeleteResolutionPersonRow(
                  avatarUrl: r.teacherAvatarUrl ?? '',
                  title: r.teacherFullName,
                  subtitle: r.classDisplayName,
                  onRemove: () => _confirmRemoveOne(context, vm, r),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            width: double.infinity,
            onPressed: () => _confirmClearAll(context, vm, rows.length),
            child: Text(
              'Clear all ${rows.length} assignment${rows.length == 1 ? '' : 's'}',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveOne(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
    SubjectDeleteTeacherAssignment entry,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Unassign teacher?',
      message:
          '${entry.teacherFullName} will no longer teach ${vm.target.name} in '
          '${entry.classDisplayName}.',
      confirmLabel: 'Unassign',
      destructive: true,
    );
    if (!confirmed) return;
    await vm.removeTeacherAssignment(entry);
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
    int count,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Clear $count assignment${count == 1 ? '' : 's'}?',
      message:
          'Every teacher assigned to ${vm.target.name} will be unassigned.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed) return;
    await vm.clearAllTeacherAssignments();
  }
}

class _StudentsSection extends StatelessWidget {
  const _StudentsSection({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final count = vm.preflight!.enrolledStudentsCount;
    return DeleteResolutionSectionShell(
      icon: HugeIcons.strokeRoundedStudent,
      iconColor: Colors.deepPurpleAccent,
      title: 'Student enrollments',
      count: count,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSurfaceCard(
            child: AppElevatedCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: AppText(
                '$count student${count == 1 ? '' : 's'} currently enrolled '
                'in ${vm.target.name}.',
                colorType: AppTextColor.textMute,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            width: double.infinity,
            onPressed: () => _confirmUnenrollAll(context, vm, count),
            child: Text('Unenroll all $count student${count == 1 ? '' : 's'}'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnenrollAll(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
    int count,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Unenroll $count student${count == 1 ? '' : 's'}?',
      message:
          'They\'ll no longer be enrolled in ${vm.target.name}. Their other '
          'enrollments are kept.',
      confirmLabel: 'Unenroll',
      destructive: true,
    );
    if (!confirmed) return;
    await vm.unenrollAllStudents();
  }
}

class _DeactivateCard extends StatelessWidget {
  const _DeactivateCard({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DeleteResolutionDeactivateCard(
      description:
          'Hides the subject from active lists without removing it from any '
          'class, teacher, or student. You keep all history.',
      buttonLabel: 'Deactivate this subject',
      onPressed: () => _confirm(context, vm),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Deactivate subject?',
      message:
          '${vm.target.name} will be hidden from active lists. Nothing else '
          'changes.',
      confirmLabel: 'Deactivate',
    );
    if (!confirmed || !context.mounted) return;
    final result = await vm.finalizeDeactivate();
    if (!context.mounted) return;
    if (result == SubjectDeleteResolutionResult.deactivated) {
      Navigator.of(context).pop(result);
    }
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DeleteResolutionDeleteButton(
      entityDisplayName: vm.target.name,
      enabled: vm.canDelete,
      onPressed: () => _confirm(context, vm),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await showDeleteResolutionConfirmDialog(
      context,
      title: 'Delete subject?',
      message:
          '${vm.target.name} will be permanently removed. This cannot be '
          'undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await vm.finalizeDelete();
    if (!context.mounted) return;
    if (result == SubjectDeleteResolutionResult.deleted) {
      Navigator.of(context).pop(result);
    }
  }
}
