import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/database/family_realm_service.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/student_detail_view_model.dart';
import 'package:hamrash_admin/viewModel/students_view_model.dart';
import 'package:hamrash_admin/views/students/create_parent_view.dart';
import 'package:hamrash_admin/views/students/create_student_view.dart';
import 'package:hamrash_admin/views/students/widgets/parent_avatar.dart';
import 'package:hamrash_admin/views/students/widgets/student_avatar.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/haptic_list_tile.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

class StudentDetailView extends StatefulWidget {
  const StudentDetailView({
    super.key,
    required this.student,
    required this.studentsViewModel,
  });

  final StudentModel student;
  final StudentsViewModel studentsViewModel;

  @override
  State<StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<StudentDetailView> {
  late StudentDetailViewModel viewModel;

  void _openEdit() {
    Navigator.push<StudentModel>(
      context,
      NavigationService.generalPageRouteBuilder(
        screen: CreateStudentView(
          existing: viewModel.student,
          studentsViewModel: widget.studentsViewModel,
        ),
      ),
    ).then((updated) {
      if (updated != null && mounted) {
        viewModel.replaceStudent(updated);
        viewModel.init(); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StudentDetailViewModel>.reactive(
      viewModelBuilder: () => StudentDetailViewModel(
        initial: widget.student,
        parent: widget.studentsViewModel,
      ),
      onViewModelReady: (m) {
        viewModel = m;
        m.init();
      },
      builder: (context, m, _) {
        final s = m.student;
        return DefaultScaffold(
          title: 'Student Details',
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
                  _AvatarSection(student: s),
                  const SizedBox(height: AppSpacing.xl),
                  if (_hasContact(s)) ...[
                    const _SectionLabel(label: 'Contact'),
                    const SizedBox(height: AppSpacing.sm),
                    _contactCard(s),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (_hasPersonal(s)) ...[
                    const _SectionLabel(label: 'Personal'),
                    const SizedBox(height: AppSpacing.sm),
                    _personalCard(s),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const _SectionLabel(label: 'Academic'),
                  const SizedBox(height: AppSpacing.sm),
                  _academicCard(m),
                  const SizedBox(height: AppSpacing.lg),
                  _SubjectsSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  _ParentsSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionLabel(label: 'Status'),
                  const SizedBox(height: AppSpacing.sm),
                  AppSurfaceCard(
                    padding: const EdgeInsets.all(5),
                    child: _InfoRow(
                      icon: s.isActive
                          ? HugeIcons.strokeRoundedCheckmarkCircle01
                          : HugeIcons.strokeRoundedCancelCircle,
                      label: 'Account',
                      value: s.isActive ? 'Active' : 'Inactive',
                      valueColor: s.isActive
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

  // ─── Static cards (read-only summaries) ──────────────────────────────

  Widget _contactCard(StudentModel s) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          if (s.email != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedMail01,
              label: 'Email',
              value: s.email!,
            ),
          if (s.email != null && s.phone != null)
            const SizedBox(height: AppSpacing.sm),
          if (s.phone != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedSmartPhone01,
              label: 'Phone',
              value: s.phone!,
            ),
        ],
      ),
    );
  }

  Widget _personalCard(StudentModel s) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          if (s.gender != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedUser,
              label: 'Gender',
              value: _capitalize(s.gender!),
            ),
          if (s.gender != null && s.dateOfBirth != null)
            const SizedBox(height: AppSpacing.sm),
          if (s.dateOfBirth != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedCalendar03,
              label: 'Date of birth',
              value: _formatDate(s.dateOfBirth!),
            ),
          if (s.dateOfBirth != null && s.state != null)
            const SizedBox(height: AppSpacing.sm),
          if (s.state != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedLocation01,
              label: 'State',
              value: s.state!,
            ),
          if (s.state != null && s.address != null)
            const SizedBox(height: AppSpacing.sm),
          if (s.address != null)
            _InfoRow(
              icon: HugeIcons.strokeRoundedHome01,
              label: 'Address',
              value: s.address!,
            ),
        ],
      ),
    );
  }

  Widget _academicCard(StudentDetailViewModel m) {
    final s = m.student;
    final classDisplay = m.currentClass?.displayName ?? '—';
    final code = m.claimCode;
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          _InfoRow(
            icon: HugeIcons.strokeRoundedSchool,
            label: 'Class',
            value: classDisplay,
            valueColor: m.currentClass == null
                ? LightColors.textTextMute
                : null,
          ),
          if (s.admissionNumber != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: HugeIcons.strokeRoundedIdentityCard,
              label: 'Admission #',
              value: s.admissionNumber!,
            ),
          ],
          if (s.admissionDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: HugeIcons.strokeRoundedCalendar03,
              label: 'Admission date',
              value: _formatDate(s.admissionDate!),
            ),
          ],
          if (code != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: HugeIcons.strokeRoundedQrCode,
              label: 'Claim code',
              value: code.code,
              canCopyValue: true,
              valueColor: code.usedAt != null
                  ? LightColors.successSuccessDefault
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  bool _hasContact(StudentModel s) => s.email != null || s.phone != null;
  bool _hasPersonal(StudentModel s) =>
      s.gender != null ||
      s.state != null ||
      s.address != null ||
      s.dateOfBirth != null;

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUBJECTS SECTION
// ═══════════════════════════════════════════════════════════════════════

class _SubjectsSection extends StatelessWidget {
  const _SubjectsSection({required this.vm});

  final StudentDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final enrolled = vm.enrolledSubjects;
    final hasClass = vm.currentClass != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(label: 'Subjects'),
            const Spacer(),
            AppHugeIconButton(
              hugeIcon: HugeIcons.strokeRoundedAdd01,
              hugeIconStrokeWidth: 2,
              hugeIconRasterSize: 22,
              foregroundColorType: AppButtonForegroundColor.textInverted,
              onPressed: hasClass ? () => _addSubject(context) : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !hasClass
              ? _EmptyHint(
                  key: const ValueKey('no-class'),
                  icon: HugeIcons.strokeRoundedSchool,
                  iconColor: Colors.blueAccent,
                  title: 'Set their class first',
                  subtitle: 'Tap the pencil to assign a class',
                )
              : enrolled.isEmpty
                  ? _EmptyHint(
                      key: const ValueKey('no-subjects'),
                      icon: HugeIcons.strokeRoundedBookOpen01,
                      iconColor: Colors.deepPurpleAccent,
                      title: 'No subjects yet',
                      subtitle: 'Tap + to enroll in a subject',
                    )
                  : _EnrolledList(
                      key: const ValueKey('list'),
                      vm: vm,
                      onRemove: (id) => _confirmRemove(context, id),
                    ),
        ),
      ],
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    final available = await vm.availableSubjectsForClass();
    if (!context.mounted) return;
    if (available.isEmpty) {
      await _infoDialog(
        context,
        title: 'No subjects available',
        message:
            '${vm.currentClass?.displayName ?? 'This class'} has no remaining subjects this student isn\'t already enrolled in.',
      );
      return;
    }
    final subject = await ListBottomSheet.show<SubjectModel, SubjectModel>(
      context: context,
      title: 'Select subject',
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedBookOpen01,
        size: 30,
        strokeWidth: 2,
        color: Colors.deepPurpleAccent,
      ),
      items: available,
      itemBuilder: (ctx, s, _) => HapticListTile(
        title: AppText(
          s.name,
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w500,
        ),
        onTap: () => Navigator.of(ctx).pop(s),
      ),
    );
    if (subject == null || subject.id == null) return;
    await vm.enrollInSubject(subject.id!);
  }

  Future<void> _confirmRemove(BuildContext context, String enrollmentId) async {
    final confirmed = await _confirmDialog(
      context,
      title: 'Remove subject?',
      message: 'Drop this subject from the student\'s enrollment.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed) await vm.unenrollFromSubject(enrollmentId);
  }
}

class _EnrolledList extends StatelessWidget {
  const _EnrolledList({
    super.key,
    required this.vm,
    required this.onRemove,
  });

  final StudentDetailViewModel vm;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final rows = vm.enrollments;
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          for (final e in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppElevatedCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedBookOpen01,
                          size: 16,
                          strokeWidth: 1.8,
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppText(
                        vm.subjectById(e.subjectId)?.name ?? 'Unknown subject',
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
                      onPressed: () => onRemove(e.id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENTS SECTION
// ═══════════════════════════════════════════════════════════════════════

class _ParentsSection extends StatelessWidget {
  const _ParentsSection({required this.vm});

  final StudentDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(label: 'Parents & guardians'),
            const Spacer(),
            AppHugeIconButton(
              hugeIcon: HugeIcons.strokeRoundedAdd01,
              hugeIconStrokeWidth: 2,
              hugeIconRasterSize: 22,
              foregroundColorType: AppButtonForegroundColor.textInverted,
              onPressed: () => _addParent(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: vm.parents.isEmpty
              ? _EmptyHint(
                  key: const ValueKey('no-parents'),
                  icon: HugeIcons.strokeRoundedUserGroup,
                  iconColor: Colors.teal,
                  title: 'No parents linked yet',
                  subtitle: 'Tap + to add a parent or guardian',
                )
              : _ParentsList(
                  key: const ValueKey('list'),
                  vm: vm,
                  onAction: (rel) => _showParentActions(context, rel),
                ),
        ),
      ],
    );
  }

  // ─── Add parent flow ────────────────────────────────────────────────

  Future<void> _addParent(BuildContext context) async {
    final choice = await ListBottomSheet.show<_AddParentChoice, _AddParentChoice>(
      context: context,
      title: 'Add a parent',
      snappingConfig: SheetSnappingConfig([0.3]),
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedUserGroup,
        size: 30,
        strokeWidth: 2,
        color: Colors.teal,
      ),
      items: _AddParentChoice.values,
      itemBuilder: (ctx, choice, _) => HapticListTile(
        leading: HugeIcon(
          icon: choice.icon,
          size: 22,
          strokeWidth: 1.8,
          color: LightColors.textTextInverted,
        ),
        title: AppText(
          choice.label,
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w500,
        ),
        subtitle: AppText(
          choice.subtitle,
          colorType: AppTextColor.textMute,
          fontSize: 12,
        ),
        onTap: () => NavigationService.popScreen(choice),
      ),
    );
    if (choice == null || !context.mounted) return;

    final ParentModel? parent;
    if (choice == _AddParentChoice.existing) {
      parent = await _pickExistingParent(context);
    } else {
      parent = await NavigationService.animatedNavigation<ParentModel>(

        screen:const CreateParentView(),
      );
    }
    if (parent == null || parent.id == null || !context.mounted) return;

    final rel = await _pickRelationship(context);
    if (rel == null || !context.mounted) return;

    final makePrimary = await _askPrimary(context);
    if (!context.mounted) return;

    await vm.linkParent(
      parentId: parent.id!,
      relationship: rel,
      isPrimary: makePrimary,
    );
  }

  Future<ParentModel?> _pickExistingParent(BuildContext context) async {
    final candidates = vm.unlinkedParents();
    if (candidates.isEmpty) {
      await _infoDialog(
        context,
        title: 'No parents to link',
        message:
            'There are no cached parents that aren\'t already linked to this student. Try "Add new parent" instead.',
      );
      return null;
    }
    return ListBottomSheet.show<ParentModel, ParentModel>(
      context: context,
      title: 'Pick a parent',
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedUserGroup,
        size: 30,
        strokeWidth: 2,
        color: Colors.teal,
      ),
      items: candidates,
      itemBuilder: (ctx, p, _) => HapticListTile(
        leading: ParentAvatar(parent: p, size: 36),
        title: AppText(
          p.fullName,
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w500,
        ),
        subtitle: p.email != null
            ? AppText(p.email!, colorType: AppTextColor.textMute, fontSize: 12)
            : null,
        onTap: () => NavigationService.popScreen(p),
      ),
    );
  }

  Future<String?> _pickRelationship(BuildContext context) {
    return ListBottomSheet.show<String, String>(
      context: context,
      title: 'Relationship to student',
      snappingConfig: SheetSnappingConfig([0.4]),
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedUserSwitch,
        size: 30,
        strokeWidth: 2,
        color: Colors.orange,
      ),
      items: StudentParentRelationship.all,
      itemBuilder: (ctx, value, _) => HapticListTile(
        title: AppText(
          StudentParentRelationship.display(value),
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w500,
        ),
        onTap: () => Navigator.of(ctx).pop(value),
      ),
    );
  }

  Future<bool> _askPrimary(BuildContext context) async {
    if (vm.parents.isEmpty) return true; // first parent = primary by default
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Primary contact?'),
        content: const Text(
          'Make this parent the primary contact for the student? The current '
          'primary will be unset.',
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationService.popScreen(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => NavigationService.popScreen(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Per-parent action sheet ────────────────────────────────────────

  Future<void> _showParentActions(
    BuildContext context,
    ParentOfStudent rel,
  ) async {
    final action = await ListBottomSheet.show<_ParentAction, _ParentAction>(
      context: context,
      title: rel.parent.fullName,
      snappingConfig: SheetSnappingConfig([0.45]),
      headerImage: ParentAvatar(parent: rel.parent, size: 30),
      items: [
        _ParentAction.changeRelationship,
        if (!rel.link.isPrimary) _ParentAction.makePrimary,
        _ParentAction.unlink,
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
          colorType: item.isDestructive ? null : AppTextColor.textInverted,
          color: item.isDestructive ? LightColors.errorErrorDefault : null,
          fontWeight: FontWeight.w500,
        ),
        onTap: () => NavigationService.popScreen(item),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _ParentAction.changeRelationship:
        final newRel = await _pickRelationship(context);
        if (newRel == null) return;
        await vm.updateLink(linkId: rel.link.id, relationship: newRel);
      case _ParentAction.makePrimary:
        await vm.updateLink(linkId: rel.link.id, isPrimary: true);
      case _ParentAction.unlink:
        if (!context.mounted) return;
        final confirmed = await _confirmDialog(
          context,
          title: 'Remove parent?',
          message:
              '${rel.parent.fullName} will no longer be linked to this student.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed) await vm.unlinkParent(rel.link.id);
    }
  }
}

class _ParentsList extends StatelessWidget {
  const _ParentsList({
    super.key,
    required this.vm,
    required this.onAction,
  });

  final StudentDetailViewModel vm;
  final ValueChanged<ParentOfStudent> onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          for (final rel in vm.parents)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppElevatedCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    ParentAvatar(parent: rel.parent, size: 40),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: AppText(
                                  rel.parent.fullName,
                                  colorType: AppTextColor.textInverted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (rel.link.isPrimary) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const AppText(
                                    'Primary',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            StudentParentRelationship.display(
                                rel.link.relationship),
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
                      hugeIconRasterSize: 22,
                      foregroundColorType: AppButtonForegroundColor.textInverted,
                      onPressed: () => onAction(rel),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _AddParentChoice {
  existing(
    'Link existing parent',
    'Pick from already-added parents',
    HugeIcons.strokeRoundedLink02,
  ),
  newParent(
    'Add new parent',
    'Create a parent profile, then link them',
    HugeIcons.strokeRoundedUserAdd01,
  );

  const _AddParentChoice(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final List<List<dynamic>> icon;
}

enum _ParentAction {
  changeRelationship(
    'Change relationship',
    HugeIcons.strokeRoundedUserSwitch,
    isDestructive: false,
  ),
  makePrimary(
    'Make primary contact',
    HugeIcons.strokeRoundedStar,
    isDestructive: false,
  ),
  unlink(
    'Remove from student',
    HugeIcons.strokeRoundedDelete02,
    isDestructive: true,
  );

  const _ParentAction(this.label, this.icon, {required this.isDestructive});
  final String label;
  final List<List<dynamic>> icon;
  final bool isDestructive;
}

// ═══════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ═══════════════════════════════════════════════════════════════════════

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          StudentAvatar(student: student, size: 100),
          const SizedBox(height: AppSpacing.md),
          AppText(
            student.fullName,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            colorType: AppTextColor.textInverted,
            textAlign: TextAlign.center,
          ),
          if (student.admissionNumber != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              student.admissionNumber!,
              colorType: AppTextColor.textMute,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
    this.canCopyValue = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool canCopyValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canCopyValue
          ? () {
              HapticHelpers.vibrate(VibrationType.light);
              Clipboard.setData(ClipboardData(text: value));
              ViewUtil.showSuccessSnackBar('Copied to clipboard');
            }
          : null,
      child: AppElevatedCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: icon,
                  size: 18,
                  strokeWidth: 1.8,
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
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: AppElevatedCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 22,
                  strokeWidth: 1.8,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    colorType: AppTextColor.textInverted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    subtitle,
                    colorType: AppTextColor.textMute,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Dialog helpers (shared by both sections)
// ═══════════════════════════════════════════════════════════════════════

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
