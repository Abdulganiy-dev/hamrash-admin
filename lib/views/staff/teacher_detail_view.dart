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
import 'package:hamrash_admin/widgets/person_detail/detail_dialogs.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_empty_hint.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_helpers.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_info_card.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_profile_header.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_section_label.dart';
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
                  DetailProfileHeader(
                    avatar: TeacherAvatar(teacher: teacher, size: 100),
                    name: teacher.fullName,
                    subtitle: teacher.email,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (hasContactInfo(email: teacher.email, phone: teacher.phone)) ...[
                    const DetailSectionLabel(label: 'Contact'),
                    const SizedBox(height: AppSpacing.sm),
                    contactInfoCard(email: teacher.email, phone: teacher.phone),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (_hasPersonal(teacher, m)) ...[
                    const DetailSectionLabel(label: 'Personal'),
                    const SizedBox(height: AppSpacing.sm),
                    _personalCard(teacher, m),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _HomeroomSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  _TeachesSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  const DetailSectionLabel(label: 'Status'),
                  const SizedBox(height: AppSpacing.sm),
                  accountStatusCard(isActive: teacher.isActive),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _personalCard(TeacherModel t, TeacherDetailViewModel m) {
    final code = m.teacherCode;
    return DetailInfoCard(
      entries: [
        if (t.gender != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedUser,
            label: 'Gender',
            value: detailCapitalize(t.gender!),
          ),
        if (t.state != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedLocation01,
            label: 'State',
            value: t.state!,
          ),
        if (t.address != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedHome01,
            label: 'Address',
            value: t.address!,
          ),
        if (code != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedQrCode,
            label: 'Claim Code',
            value: code.code,
            canCopyValue: true,
            valueColor: code.usedAt != null
                ? LightColors.successSuccessDefault
                : null,
          ),
      ],
    );
  }

  bool _hasPersonal(TeacherModel t, TeacherDetailViewModel m) =>
      t.gender != null ||
      t.state != null ||
      t.address != null ||
      m.teacherCode != null;
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
        const DetailSectionLabel(label: 'Classroom'),
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
              : DetailEmptyHint(
                  key: const ValueKey('empty'),
                  icon: HugeIcons.strokeRoundedSchool,
                  iconColor: Colors.blueAccent,
                  title: 'Not a classroom teacher',
                  subtitle: 'Tap to assign a class',
                  onTap: () => _startAssign(context),
                  showTrailingArrow: true,
                  iconInBox: false,
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
        final confirmed = await detailConfirmDialog(
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
            const DetailSectionLabel(label: 'Teaches'),
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
              ? DetailEmptyHint(
                  key: const ValueKey('empty'),
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  iconColor: Colors.deepPurpleAccent,
                  title: 'No subjects yet',
                  subtitle: 'Tap + to add the first subject',
                  onTap: () => _addAssignment(context),
                  showTrailingArrow: true,
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
      await detailInfoDialog(
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
    final confirmed = await detailConfirmDialog(
      context,
      title: 'Remove subject?',
      message: 'Stop teaching $subject in $cls?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed) await vm.removeTeachingAssignment(assignment.id);
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

Future<ClassModel?> _pickClass(
  BuildContext context,
  TeacherDetailViewModel vm,
) {
  if (vm.classes.isEmpty) {
    return detailInfoDialog(
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

