import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_delete_preflight.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/viewModel/class_delete_resolution_view_model.dart';
import 'package:hamrash_admin/views/subjects/subject_delete_resolution_view.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';
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
                    _Headline(target: widget.classToDelete),
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
                      _AllClearCard(),
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

// ═══════════════════════════════════════════════════════════════════════
// HEADLINE + AUTO-REMOVED FOOTNOTE
// ═══════════════════════════════════════════════════════════════════════

class _Headline extends StatelessWidget {
  const _Headline({required this.target});
  final ClassModel target;

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
          '"${target.displayName}"',
          colorType: AppTextColor.textInverted,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppText(
          'Take care of the items below. The class can be deleted once every '
          'section is cleared.',
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ),
      ],
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
      if (curriculum > 0) '$curriculum curriculum link${curriculum == 1 ? '' : 's'}',
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

// ═══════════════════════════════════════════════════════════════════════
// STUDENTS SECTION
// ═══════════════════════════════════════════════════════════════════════

class _StudentsSection extends StatelessWidget {
  const _StudentsSection({required this.vm});
  final ClassDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final students = vm.preflight!.students;
    return SectionShell(
      icon: HugeIcons.strokeRoundedStudent,
      iconColor: Colors.blueAccent,
      title: 'Enrolled students',
      count: students.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSurfaceCard(child: Column(
            children: [
                for (final s in students)
            Padding(
              padding: EdgeInsets.only(bottom: students.indexOf(s) == students.length - 1 ? 0 : AppSpacing.sm),
              child: AppElevatedCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    CachedNetworkImageWidget(imageUrl: s.avatarUrl ?? '',width: 35,height: 35,borderRadius: 40,),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            s.fullName,
                            colorType: AppTextColor.textInverted,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (s.admissionNumber != null) ...[
                            const SizedBox(height: 2),
                            AppText(
                              s.admissionNumber!,
                              colorType: AppTextColor.textMute,
                              fontSize: 12,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
            ],
          )),
          
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
      await _infoDialog(
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
      title: 'Move ${students.length} student${students.length == 1 ? '' : 's'} to…',
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

    final confirmed = await _confirmDialog(
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
    final confirmed = await _confirmDialog(
      context,
      title: 'Unassign ${students.length} student${students.length == 1 ? '' : 's'}?',
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

// ═══════════════════════════════════════════════════════════════════════
// HOMEROOM TEACHERS SECTION
// ═══════════════════════════════════════════════════════════════════════

class _HomeroomSection extends StatelessWidget {
  const _HomeroomSection({required this.vm});
  final ClassDeleteResolutionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final teachers = vm.preflight!.homeroomTeachers;
    return SectionShell(
      icon: HugeIcons.strokeRoundedTeacher,
      iconColor: Colors.orange,
      title: 'Homeroom assignment',
      count: teachers.length,
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final t in teachers)
              Padding(
                padding: EdgeInsets.only(bottom: teachers.indexOf(t) == teachers.length - 1 ? 0 : AppSpacing.sm),
                child: AppElevatedCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      CachedNetworkImageWidget(imageUrl: t.avatarUrl ?? '',width: 35,height: 35,borderRadius: 40,),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              t.fullName,
                              colorType: AppTextColor.textInverted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              _roleLabel(t.homeroomRole),
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
                        onPressed: () => _confirmClear(context, vm, t),
                      ),
                    ],
                  ),
                ),
              ),
          
          ],
        ),
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
    final confirmed = await _confirmDialog(
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
                  'No more blockers. The class can be deleted now.',
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
  final ClassDeleteResolutionViewModel vm;

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
            'Hides the class from active lists without removing any students, '
            'teachers, or history.',
            colorType: AppTextColor.textMute,
            fontSize: 12,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            width: double.infinity,
            onPressed: () => _confirm(context, vm),
            child: const Text('Deactivate this class'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    ClassDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await _confirmDialog(
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
    final enabled = vm.canDelete;
    return AppPrimaryButton(
      width: double.infinity,
      backgroundColorType: enabled
          ? AppButtonBackgroundColor.error
          : AppButtonBackgroundColor.errorMute,
      foregroundColor: Colors.white,
      onPressed: enabled ? () => _confirm(context, vm) : null,
      child: Text(
        'Delete "${vm.target.displayName}"',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    ClassDeleteResolutionViewModel vm,
  ) async {
    final confirmed = await _confirmDialog(
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
            foregroundColor:
                destructive ? LightColors.errorErrorDefault : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _infoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showAdaptiveDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
