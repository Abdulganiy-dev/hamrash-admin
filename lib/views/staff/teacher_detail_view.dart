import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/teacher_detail_view_model.dart';
import 'package:hamrash_admin/viewModel/teachers_view_model.dart';
import 'package:hamrash_admin/views/staff/create_teacher_view.dart';
import 'package:hamrash_admin/views/staff/widgets/teacher_avatar.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/haptic_list_tile.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

class TeacherDetailView extends StatefulWidget {
  const TeacherDetailView({
    super.key,
    required this.teacher,
    required this.teachersViewModel,
  });

  final TeacherModel teacher;
  final TeachersViewModel teachersViewModel;

  @override
  State<TeacherDetailView> createState() => _TeacherDetailViewState();
}

class _TeacherDetailViewState extends State<TeacherDetailView> {
  late TeacherDetailViewModel viewModel;

  void _openEdit() {
    Navigator.push<TeacherModel>(
      context,
      NavigationService.generalPageRouteBuilder(
        screen: CreateTeacherView(
          existing: viewModel.teacher,
          teachersViewModel: widget.teachersViewModel,
        ),
      ),
    ).then((updated) {
      if (updated != null && mounted) {
        viewModel.replaceTeacher(updated);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TeacherDetailViewModel>.reactive(
      viewModelBuilder: () => TeacherDetailViewModel(
        initial: widget.teacher,
        parent: widget.teachersViewModel,
      ),
      onViewModelReady: (m) {
        viewModel = m;
        m.init();
      },
      builder: (context, m, _) {
        final teacher = m.teacher;
        return DefaultScaffold(
          title: 'Teacher Details',
          showBackButton: true,
          busy: m.busy,
          actions: [
            AppHugeIconButton(
              hugeIcon: HugeIcons.strokeRoundedPencilEdit01,
              hugeIconStrokeWidth: 2,
              hugeIconRasterSize: 30,
              foregroundColorType: AppButtonForegroundColor.textInverted,
              onPressed: _openEdit,
            ),
          ],
          appBarType: DefaultScaffoldAppBarType.standard,
          body: Builder(
            builder: (ctx) => SingleChildScrollView(
              child: ScaffoldColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ScaffoldInsets.of(ctx).bodyTopInset + 15),
                  _AvatarSection(teacher: teacher),
                  const SizedBox(height: AppSpacing.xl),
                  if (_hasContact(teacher)) ...[
                    const _SectionLabel(label: 'Contact'),
                    const SizedBox(height: AppSpacing.sm),
                    _contactCard(teacher),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (_hasPersonal(teacher)) ...[
                    const _SectionLabel(label: 'Personal'),
                    const SizedBox(height: AppSpacing.sm),
                    _personalCard(teacher),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _HomeroomSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  _TeachesSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionLabel(label: 'Status'),
                  const SizedBox(height: AppSpacing.sm),
                  AppSurfaceCard(
                    padding: const EdgeInsets.all(5),
                    child: _InfoRow(
                      icon: teacher.isActive
                          ? HugeIcons.strokeRoundedCheckmarkCircle01
                          : HugeIcons.strokeRoundedCancelCircle,
                      label: 'Account',
                      value: teacher.isActive ? 'Active' : 'Inactive',
                      valueColor: teacher.isActive
                          ? Colors.green
                          : LightColors.errorErrorDefault,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Contact + Personal cards (unchanged behaviour) ────────────────

  Widget _contactCard(TeacherModel t) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          if (t.email != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedMail01,
              label: 'Email',
              value: t.email!,
            ),
          if (t.email != null && t.phone != null)
            const SizedBox(height: AppSpacing.sm),
          if (t.phone != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedSmartPhone01,
              label: 'Phone',
              value: t.phone!,
            ),
        ],
      ),
    );
  }

  Widget _personalCard(TeacherModel t) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          if (t.gender != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedUser,
              label: 'Gender',
              value: _capitalize(t.gender!),
            ),
          if (t.gender != null && t.state != null)
            const SizedBox(height: AppSpacing.sm),
          if (t.state != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedLocation01,
              label: 'State',
              value: t.state!,
            ),
          if (t.state != null && t.address != null)
            const SizedBox(height: AppSpacing.sm),
          if (t.address != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedHome01,
              label: 'Address',
              value: t.address!,
            ),
        ],
      ),
    );
  }

  bool _hasContact(TeacherModel t) => t.email != null || t.phone != null;
  bool _hasPersonal(TeacherModel t) =>
      t.gender != null || t.state != null || t.address != null;

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;
}

// ═══════════════════════════════════════════════════════════════════════
// Classroom SECTION
// ═══════════════════════════════════════════════════════════════════════

class _HomeroomSection extends StatelessWidget {
  const _HomeroomSection({required this.vm});

  final TeacherDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Classroom'),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: vm.hasHomeroom
              ? _AssignedHomeroomCard(
                  key: const ValueKey('assigned'),
                  vm: vm,
                  onTap: () => _showOptions(context),
                )
              : _EmptyHomeroomCard(
                  key: const ValueKey('empty'),
                  onTap: () => _startAssign(context),
                ),
        ),
      ],
    );
  }

  // ─── Flows ────────────────────────────────────────────────────────────

  Future<void> _startAssign(BuildContext context) async {
    final cls = await _pickClass(context, vm);
    if (cls == null || !context.mounted) return;
    final role = await _pickRole(context);
    if (role == null) return;
    await vm.setHomeroom(classId: cls.id!, role: role);
  }

  Future<void> _showOptions(BuildContext context) async {
    final action = await ListBottomSheet.show<_HomeroomAction, _HomeroomAction>(
      context: context,
      title: 'Classroom options',
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedSchool,
        size: 30,
        strokeWidth: 2,
        color: Colors.blueAccent,
      ),
      snappingConfig: SheetSnappingConfig([0.4]),
      items: const [
        _HomeroomAction.changeClass,
        _HomeroomAction.changeRole,
        _HomeroomAction.remove,
      ],
      itemBuilder: (ctx, item, _) => HapticListTile(
        leading: HugeIcon(
          icon: item.icon,
          size: 22,
          strokeWidth: 1.8,
          color: item.isDestructive
              ? LightColors.errorErrorDefault
              : LightColors.textTextInverted,
        ),
        title: AppText(
          item.label,
          colorType: item.isDestructive
              ? null
              : AppTextColor.textInverted,
          color: item.isDestructive ? LightColors.errorErrorDefault : null,
          fontWeight: FontWeight.w500,
        ),
        onTap: () => NavigationService.popScreen(item),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _HomeroomAction.changeClass:
        final cls = await _pickClass(context, vm);
        if (cls == null) return;
        await vm.setHomeroom(
          classId: cls.id!,
          role: vm.teacher.homeroomRole ?? HomeroomRole.main,
        );
      case _HomeroomAction.changeRole:
        if (!context.mounted) return;
        final role = await _pickRole(context);
        if (role == null) return;
        await vm.setHomeroomRole(role);
      case _HomeroomAction.remove:
        if (!context.mounted) return;
        final confirmed = await _confirmDialog(
          context,
          title: 'Remove homeroom?',
          message:
              'This teacher will no longer be the homeroom for ${vm.homeroomClass?.displayName ?? 'their class'}.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed) await vm.clearHomeroom();
    }
  }
}

class _EmptyHomeroomCard extends StatelessWidget {
  const _EmptyHomeroomCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(5),
        child: AppElevatedCard(
          child: Row(
            children: [
              const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSchool,
                  size: 20,
                  strokeWidth: 2,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Not a classroom teacher',
                      colorType: AppTextColor.textInverted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      'Tap to assign a class',
                      colorType: AppTextColor.textMute,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 20,
                strokeWidth: 2,
                color: LightColors.textTextMute,
              ),
            ],
          ),
        ),
      ),
    ).hapticFeedback();
  }
}

class _AssignedHomeroomCard extends StatelessWidget {
  const _AssignedHomeroomCard({
    super.key,
    required this.vm,
    required this.onTap,
  });

  final TeacherDetailViewModel vm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cls = vm.homeroomClass;
    final role = vm.homeroomRoleDisplay ?? '—';
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AbsorbPointer(
          child: AppElevatedCard(
            child: Row(
              children: [
                const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSchool,
                    size: 20,
                    strokeWidth: 2,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        cls?.displayName ?? 'Unknown class',
                        colorType: AppTextColor.textInverted,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        role,
                        colorType: AppTextColor.textMute,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                AppHugeIconButton(
                  hugeIcon: HugeIcons.strokeRoundedMoreHorizontal,
                  hugeIconStrokeWidth: 2,
                  hugeIconRasterSize: 20,
                  foregroundColorType: AppButtonForegroundColor.textInverted,
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      ).hapticFeedback(),
    );
  }
}

enum _HomeroomAction {
  changeClass(
    'Change class',
    HugeIcons.strokeRoundedExchange01,
    isDestructive: false,
  ),
  changeRole(
    'Change role',
    HugeIcons.strokeRoundedUserSwitch,
    isDestructive: false,
  ),
  remove(
    'Remove classroom',
    HugeIcons.strokeRoundedDelete02,
    isDestructive: true,
  );

  const _HomeroomAction(this.label, this.icon, {required this.isDestructive});
  final String label;
  final List<List<dynamic>> icon;
  final bool isDestructive;
}

class _TeachesSection extends StatelessWidget {
  const _TeachesSection({required this.vm});

  final TeacherDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final groups = vm.groupedAssignments();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(label: 'Teaches'),
            const Spacer(),
            AppHugeIconButton(
              hugeIcon: HugeIcons.strokeRoundedAdd01,
              hugeIconStrokeWidth: 2,
              hugeIconRasterSize: 22,
              foregroundColorType: AppButtonForegroundColor.textInverted,
              onPressed: () => _addAssignment(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: groups.isEmpty
              ? _EmptyTeachesCard(
                  key: const ValueKey('empty'),
                  onTap: () => _addAssignment(context),
                )
              : _GroupedAssignmentsCard(
                  key: const ValueKey('list'),
                  vm: vm,
                  groups: groups,
                  onRemove: (assignment) => _confirmRemove(context, assignment),
                ),
        ),
      ],
    );
  }

  Future<void> _addAssignment(BuildContext context) async {
    final cls = await _pickClass(context, vm);
    if (cls == null || !context.mounted) return;
    final available = await vm.availableSubjectsForClass(cls.id!);
    if (!context.mounted) return;
    if (available.isEmpty) {
      await _infoDialog(
        context,
        title: 'No subjects available',
        message:
            '${cls.displayName} has no remaining subjects to assign — either it has no subjects configured, or this teacher already teaches them all.',
      );
      return;
    }
    final subject = await _pickSubject(context, available);
    if (subject == null || subject.id == null) return;
    await vm.addTeachingAssignment(
      classId: cls.id!,
      subjectId: subject.id!,
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    TeacherClassSubject assignment,
  ) async {
    final subject = vm.subjectById(assignment.subjectId)?.name ?? 'this subject';
    final cls = vm.classById(assignment.classId)?.displayName ?? 'this class';
    final confirmed = await _confirmDialog(
      context,
      title: 'Remove subject?',
      message: 'Stop teaching $subject in $cls?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed) await vm.removeTeachingAssignment(assignment.id);
  }
}

class _EmptyTeachesCard extends StatelessWidget {
  const _EmptyTeachesCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(5),
        child: AppElevatedCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedBookOpen01,
                    size: 22,
                    strokeWidth: 1.8,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'No subjects yet',
                      colorType: AppTextColor.textInverted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      'Tap + to add the first subject',
                      colorType: AppTextColor.textMute,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                strokeWidth: 1.8,
                color: LightColors.textTextMute,
              ),
            ],
          ),
        ),
      ),
    ).hapticFeedback();
  }
}

class _GroupedAssignmentsCard extends StatelessWidget {
  const _GroupedAssignmentsCard({
    super.key,
    required this.vm,
    required this.groups,
    required this.onRemove,
  });

  final TeacherDetailViewModel vm;
  final List<MapEntry<ClassModel, List<TeacherClassSubject>>> groups;
  final ValueChanged<TeacherClassSubject> onRemove;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (var i = 0; i < groups.length; i++) {
      final entry = groups[i];
      tiles.add(_ClassGroupHeader(name: entry.key.displayName));
      for (final assignment in entry.value) {
        tiles.add(_AssignmentRow(
          subjectName: vm.subjectById(assignment.subjectId)?.name ??
              'Unknown subject',
          onRemove: () => onRemove(assignment),
        ));
      }
      if (i < groups.length - 1) tiles.add(const SizedBox(height: AppSpacing.sm));
    }
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: AppSpacing.sm,
      ),
      child: Column(children: tiles),
    );
  }
}

class _ClassGroupHeader extends StatelessWidget {
  const _ClassGroupHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedSchool,
            size: 14,
            strokeWidth: 1.8,
            color: LightColors.textTextMute,
          ),
          const SizedBox(width: AppSpacing.xs),
          AppText(
            name,
            colorType: AppTextColor.textMute,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ],
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.subjectName, required this.onRemove});

  final String subjectName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppElevatedCard(

        child: Row(
          children: [
            const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedBookOpen01,
                size: 18,
                strokeWidth: 2,
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppText(
                subjectName,
                colorType: AppTextColor.textInverted,
                fontWeight: FontWeight.w500,
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
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSeparator extends StatelessWidget {
  const _GroupSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Divider(
        height: 1,
        color: LightColors.strokeColourStrokeMild.withValues(alpha: 0.3),
      ),
    );
  }
}

Future<ClassModel?> _pickClass(
  BuildContext context,
  TeacherDetailViewModel vm,
) {
  if (vm.classes.isEmpty) {
    return _infoDialog(
      context,
      title: 'No classes available',
      message: 'Create a class first before making assignments.',
    ).then((_) => null);
  }
  return ListBottomSheet.show<ClassModel, ClassModel>(
    context: context,
    title: 'Select class',
    headerImage: const HugeIcon(
      icon: HugeIcons.strokeRoundedSchool,
      size: 30,
      strokeWidth: 2,
      color: Colors.blueAccent,
    ),
    items: vm.classes,
    itemBuilder: (ctx, cls, _) => HapticListTile(
      title: AppText(
        cls.displayName,
        colorType: AppTextColor.textInverted,
        fontWeight: FontWeight.w500,
      ),
      onTap: () => Navigator.of(ctx).pop(cls),
    ),
  );
}

Future<String?> _pickRole(BuildContext context) {
  return ListBottomSheet.show<String, String>(
    context: context,
    title: 'Select role',
    snappingConfig: SheetSnappingConfig([0.35]),
    headerImage: const HugeIcon(
      icon: HugeIcons.strokeRoundedUserSwitch,
      size: 30,
      strokeWidth: 2,
      color: Colors.orange,
    ),
    items: HomeroomRole.all,
    itemBuilder: (ctx, value, _) => HapticListTile(
      title: AppText(
        HomeroomRole.display(value),
        colorType: AppTextColor.textInverted,
        fontWeight: FontWeight.w500,
      ),
      subtitle: AppText(
        value == HomeroomRole.main
            ? 'Primary teacher for the class'
            : 'Supports the main teacher',
        colorType: AppTextColor.textMute,
        fontSize: 12,
      ),
      onTap: () => NavigationService.popScreen(HomeroomRole.apiName(value)),
    ),
  );
}

Future<SubjectModel?> _pickSubject(
  BuildContext context,
  List<SubjectModel> subjects,
) {
  return ListBottomSheet.show<SubjectModel, SubjectModel>(
    context: context,
    title: 'Select subject',
    headerImage: const HugeIcon(
      icon: HugeIcons.strokeRoundedBookOpen01,
      size: 30,
      strokeWidth: 2,
      color: Colors.deepPurpleAccent,
    ),
    items: subjects,
    itemBuilder: (ctx, s, _) => HapticListTile(
      title: AppText(
        s.name,
        colorType: AppTextColor.textInverted,
        fontWeight: FontWeight.w500,
      ),
      onTap: () => Navigator.of(ctx).pop(s),
    ),
  );
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

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.teacher});

  final TeacherModel teacher;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          TeacherAvatar(teacher: teacher, size: 100),
          const SizedBox(height: AppSpacing.md),
          AppText(
            teacher.fullName,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            colorType: AppTextColor.textInverted,
            textAlign: TextAlign.center,
          ),
          if (teacher.email != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              teacher.email!,
              colorType: AppTextColor.textMute,
              fontSize: 14,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppText(
      label,
      colorType: AppTextColor.textInverted,
      fontWeight: FontWeight.w700,
      fontSize: 17,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return AppElevatedCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: icon,
                size: 20,
                strokeWidth: 2,
                color: LightColors.textTextMute,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppText(label, colorType: AppTextColor.textMute, fontSize: 13),
            ],
          ),
          Flexible(
            child: valueColor != null
                ? AppText(
                    value,
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : AppText(
                    value,
                    colorType: AppTextColor.textInverted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
