import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/subject_delete_preflight.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/subject_delete_resolution_view_model.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
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
                    _Headline(target: widget.subjectToDelete),
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
                      _AllClearCard(),
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

// ═══════════════════════════════════════════════════════════════════════
// HEADLINE
// ═══════════════════════════════════════════════════════════════════════

class _Headline extends StatelessWidget {
  const _Headline({required this.target});
  final SubjectModel target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Before you can delete',
          colorType: AppTextColor.textMute,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 2),
        AppText(
          '"${target.name}"',
          colorType: AppTextColor.textInverted,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppText(
          'Take care of the items below. The subject can be deleted once every '
          'section is cleared.',
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CLASSES SECTION (curriculum)
// ═══════════════════════════════════════════════════════════════════════

class _ClassesSection extends StatelessWidget {
  const _ClassesSection({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final classes = vm.preflight!.classes;
    return _SectionShell(
      icon: HugeIcons.strokeRoundedSchool,
      iconColor: Colors.blueAccent,
      title: 'Classes using this subject',
      count: classes.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSurfaceCard(
            child: Column(
              children: [
                for (final c in classes)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: classes.indexOf(c) == classes.length - 1
                          ? 0
                          : AppSpacing.sm,
                    ),
                    child: AppElevatedCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              c.displayName,
                              colorType: AppTextColor.textInverted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppHugeIconButton(
                            hugeIcon: HugeIcons.strokeRoundedDelete02,
                            hugeIconStrokeWidth: 2,
                            hugeIconRasterSize: 18,
                            foregroundColor: LightColors.errorErrorDefault,
                            onPressed: () => _confirmRemoveOne(context, vm, c),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
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
    final confirmed = await _confirmDialog(
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
    final confirmed = await _confirmDialog(
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

// ═══════════════════════════════════════════════════════════════════════
// TEACHER ASSIGNMENTS SECTION
// ═══════════════════════════════════════════════════════════════════════

class _TeacherAssignmentsSection extends StatelessWidget {
  const _TeacherAssignmentsSection({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final rows = vm.preflight!.teacherAssignments;
    return _SectionShell(
      icon: HugeIcons.strokeRoundedTeacher,
      iconColor: Colors.orange,
      title: 'Teacher assignments',
      count: rows.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSurfaceCard(
            child: Column(
              children: [
                for (final r in rows)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: rows.indexOf(r) == rows.length - 1
                          ? 0
                          : AppSpacing.sm,
                    ),
                    child: AppElevatedCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  r.teacherFullName,
                                  colorType: AppTextColor.textInverted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                AppText(
                                  r.classDisplayName,
                                  colorType: AppTextColor.textMute,
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          ),
                          AppHugeIconButton(
                            hugeIcon: HugeIcons.strokeRoundedDelete02,
                            hugeIconStrokeWidth: 2,
                            hugeIconRasterSize: 18,
                            foregroundColor: LightColors.errorErrorDefault,
                            onPressed: () => _confirmRemoveOne(context, vm, r),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
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
    final confirmed = await _confirmDialog(
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
    final confirmed = await _confirmDialog(
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

// ═══════════════════════════════════════════════════════════════════════
// STUDENTS SECTION (count-only, bulk action)
// ═══════════════════════════════════════════════════════════════════════

class _StudentsSection extends StatelessWidget {
  const _StudentsSection({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final count = vm.preflight!.enrolledStudentsCount;
    return _SectionShell(
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
    final confirmed = await _confirmDialog(
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

// ═══════════════════════════════════════════════════════════════════════
// ALL-CLEAR + FINAL BUTTONS
// ═══════════════════════════════════════════════════════════════════════

class _AllClearCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                size: 22,
                strokeWidth: 1.8,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'All clear',
                  colorType: AppTextColor.textInverted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                const SizedBox(height: 2),
                AppText(
                  'No more blockers. The subject can be deleted now.',
                  colorType: AppTextColor.textMute,
                  fontSize: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeactivateCard extends StatelessWidget {
  const _DeactivateCard({required this.vm});
  final SubjectDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Recommended alternative',
            colorType: AppTextColor.textMute,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Deactivate instead',
            colorType: AppTextColor.textInverted,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          const SizedBox(height: 4),
          AppText(
            'Hides the subject from active lists without removing it from any '
            'class, teacher, or student. You keep all history.',
            colorType: AppTextColor.textMute,
            fontSize: 12,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            width: double.infinity,
            onPressed: () => _confirm(context, vm),
            child: const Text('Deactivate this subject'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await _confirmDialog(
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
    final enabled = vm.canDelete;
    return AppPrimaryButton(
      width: double.infinity,
      backgroundColorType: enabled
          ? AppButtonBackgroundColor.error
          : AppButtonBackgroundColor.errorMute,
      foregroundColor: Colors.white,
      onPressed: enabled ? () => _confirm(context, vm) : null,
      child: Text(
        'Delete "${vm.target.name}"',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    SubjectDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await _confirmDialog(
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

// ═══════════════════════════════════════════════════════════════════════
// Section shell + dialogs (shared with class delete; small enough to dup)
// ═══════════════════════════════════════════════════════════════════════

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.child,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 18,
                  strokeWidth: 1.8,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppText(
                title,
                colorType: AppTextColor.textInverted,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: LightColors.errorErrorDefault.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AppText(
                count.toString(),
                color: LightColors.errorErrorDefault,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

Future<bool> _confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? LightColors.errorErrorDefault : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
