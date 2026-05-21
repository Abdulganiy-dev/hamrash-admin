import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/database/family_realm_service.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
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
import 'package:hamrash_admin/widgets/person_detail/detail_dialogs.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_empty_hint.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_helpers.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_info_card.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_profile_header.dart';
import 'package:hamrash_admin/widgets/person_detail/detail_section_label.dart';
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
                  DetailProfileHeader(
                    avatar: StudentAvatar(student: s, size: 100),
                    name: s.fullName,
                    subtitle: s.admissionNumber,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (hasContactInfo(email: s.email, phone: s.phone)) ...[
                    const DetailSectionLabel(label: 'Contact'),
                    const SizedBox(height: AppSpacing.sm),
                    contactInfoCard(email: s.email, phone: s.phone),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (_hasPersonal(s)) ...[
                    const DetailSectionLabel(label: 'Personal'),
                    const SizedBox(height: AppSpacing.sm),
                    _personalCard(s),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const DetailSectionLabel(label: 'Academic'),
                  const SizedBox(height: AppSpacing.sm),
                  _academicCard(m),
                  const SizedBox(height: AppSpacing.lg),
                  _SubjectsSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  _ParentsSection(vm: m),
                  const SizedBox(height: AppSpacing.lg),
                  const DetailSectionLabel(label: 'Status'),
                  const SizedBox(height: AppSpacing.sm),
                  accountStatusCard(isActive: s.isActive),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _personalCard(StudentModel s) {
    return DetailInfoCard(
      entries: [
        if (s.gender != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedUser,
            label: 'Gender',
            value: detailCapitalize(s.gender!),
          ),
        if (s.dateOfBirth != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedCalendar03,
            label: 'Date of birth',
            value: detailFormatDate(s.dateOfBirth!),
          ),
        if (s.state != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedLocation01,
            label: 'State',
            value: s.state!,
          ),
        if (s.address != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedHome01,
            label: 'Address',
            value: s.address!,
          ),
      ],
    );
  }

  Widget _academicCard(StudentDetailViewModel m) {
    final s = m.student;
    final classDisplay = m.currentClass?.displayName ?? '—';
    final code = m.claimCode;
    return DetailInfoCard(
      entries: [
        DetailInfoEntry(
          icon: HugeIcons.strokeRoundedSchool,
          label: 'Class',
          value: classDisplay,
          valueColor:
              m.currentClass == null ? LightColors.textTextMute : null,
        ),
        if (s.admissionNumber != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedIdentityCard,
            label: 'Admission #',
            value: s.admissionNumber!,
          ),
        if (s.admissionDate != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedCalendar03,
            label: 'Admission date',
            value: detailFormatDate(s.admissionDate!),
          ),
        if (code != null)
          DetailInfoEntry(
            icon: HugeIcons.strokeRoundedQrCode,
            label: 'Claim code',
            value: code.code,
            canCopyValue: true,
            valueColor: code.usedAt != null
                ? LightColors.successSuccessDefault
                : null,
          ),
      ],
    );
  }

  bool _hasPersonal(StudentModel s) =>
      s.gender != null ||
      s.state != null ||
      s.address != null ||
      s.dateOfBirth != null;
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
            const DetailSectionLabel(label: 'Subjects'),
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
              ? DetailEmptyHint(
                  key: const ValueKey('no-class'),
                  icon: HugeIcons.strokeRoundedSchool,
                  iconColor: Colors.blueAccent,
                  title: 'Set their class first',
                  subtitle: 'Tap the pencil to assign a class',
                )
              : enrolled.isEmpty
                  ? DetailEmptyHint(
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
      await detailInfoDialog(
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
    final confirmed = await detailConfirmDialog(
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
            GestureDetector(
              onTap: () => onRemove(e.id),
              child: AbsorbPointer(
                child: Padding(
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
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).hapticFeedback(),
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
            const DetailSectionLabel(label: 'Parents & guardians'),
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
              ? DetailEmptyHint(
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
      await detailInfoDialog(
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
      snappingConfig: SheetSnappingConfig([0.3]),
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
        final confirmed = await detailConfirmDialog(
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
            GestureDetector(
              onTap: () => onAction(rel),
              child: AbsorbPointer(
                child: Padding(
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
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).hapticFeedback(),
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

