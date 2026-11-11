import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/core/bottomSheets/app_action_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/students/student_detail/student_detail_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/add_parent_sheet.dart';
import 'package:hamrash_admin/views/students/parent_detail/parent_detail_screen.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/move_arm_sheet.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/optional_subjects_sheet.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/parent_relationship_sheet.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/student_change_details_sheet.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/student_hero.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/student_parent_row.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/student_status_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';
import 'package:hamrash_admin/views/team/widgets/invite_ready_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';

/// 9.12 – 9.24 · One student. Leaders change their details, class, subjects,
/// parents and status; the owner and admins also manage their login and
/// remove them; a bursar only reads (9.12a). Pops `true` when something was
/// saved or the student was removed, so the list behind reloads.
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({
    super.key,
    required this.school,
    required this.studentId,
    this.viewModel,
  });

  final MemberSchool school;
  final String studentId;

  /// For tests: a view model built with fake services.
  final StudentDetailViewModel? viewModel;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<StudentDetailViewModel>.reactive(
        viewModelBuilder: () =>
            viewModel ??
            StudentDetailViewModel(school: school, studentId: studentId),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          title: 'Student',
          showBackButton: true,
          onBackPressed: () => NavigationService.popScreen(model.changed),
          backgroundColor: AppPalette.linen,
          actions: [
            if (!model.loading && model.error == null && model.canEdit)
              AppNavIconButton(
                icon: AppIcons.ellipsis,
                semanticLabel: 'More actions',
                onPressed: () => _openActions(context, model),
              ),
          ],
          body: AnimatedSectionContent(
            morphHeight: false,
            child: model.error != null
                ? LoadErrorView(
                    key: const ValueKey('error'),
                    onRetry: model.load,
                  )
                : model.loading
                ? const _Loading(key: ValueKey('loading'))
                : _Content(key: const ValueKey('content'), model: model),
          ),
        ),
      );

  /// 9.13 · The page's actions in one sheet.
  static void _openActions(BuildContext context, StudentDetailViewModel model) {
    final student = model.student;
    AppActionSheet.show(
      context,
      title: student.fullName,
      subtitle: model.identityMeta,
      leading: AppLeadingPicture(
        leading: AppListLeading.network(
          student.photoUrl ?? '',
          name: student.fullName,
        ),
        size: 44,
      ),
      groups: [
        [
          AppSheetAction(
            label: 'Change details',
            icon: AppIcons.pencil,
            onTap: () => _changeDetails(context, model),
          ),
          if (model.canChangeClass && student.placement != null) ...[
            AppSheetAction(
              label: 'Move to another arm',
              icon: AppIcons.arrowLeftRight,
              onTap: () => _moveArm(context, model),
            ),
            if (student.placement!.optional.isNotEmpty)
              AppSheetAction(
                label: 'Change optional subjects',
                icon: AppIcons.bookOpen,
                onTap: () => _optionalSubjects(context, model),
              ),
          ],
          AppSheetAction(
            label: 'Change status',
            icon: AppIcons.clock,
            onTap: () => _changeStatus(context, model),
          ),
        ],
        if (model.canManageAccess)
          [
            AppSheetAction(
              label: 'Remove student',
              icon: AppIcons.userMinus,
              isDestructive: true,
              onTap: () => _remove(context, model),
            ),
          ],
      ],
    );
  }

  static Future<T?> _sheet<T>(BuildContext context, Widget sheet) =>
      Navigator.of(context).push<T>(
        AppSheetRoute<T>(size: AppSheetSize.floating, child: sheet),
      );

  /// 9.14
  static Future<void> _changeDetails(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final saved = await StudentChangeDetailsSheet.show(
      context,
      student: model.student,
      onSave: model.saveDetails,
    );
    if (saved == true) AppToast.show('Details saved');
  }

  /// 9.15
  static Future<void> _moveArm(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final placement = model.student.placement!;
    final List<ArmChoice>? arms;
    try {
      arms = await model.loadArmChoices();
    } catch (_) {
      AppToast.show("Couldn't load the arms. Try again.", type: AppToastType.error);
      return;
    }
    if (arms == null || !context.mounted) return;
    final dropped = await MoveArmSheet.show(
      context,
      className: placement.className,
      currentArmId: placement.armId,
      arms: arms,
      onMove: (armId) => model.moveToArm(armId),
    );
    if (dropped == null) return;
    AppToast.show(
      dropped == 0
          ? 'Moved to ${model.student.placement?.armLabel ?? 'the new arm'}'
          : 'Moved. $dropped optional '
                '${dropped == 1 ? 'subject' : 'subjects'} dropped',
    );
  }

  /// 9.16
  static Future<void> _optionalSubjects(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final saved = await OptionalSubjectsSheet.show(
      context,
      firstName: model.student.firstNameOnly,
      placement: model.student.placement!,
      onSave: model.saveOptionalSubjects,
    );
    if (saved == true) AppToast.show('Subjects saved');
  }

  /// 9.21
  static Future<void> _changeStatus(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final chosen = await StudentStatusSheet.show(
      context,
      current: model.student.status,
    );
    if (chosen == null || !context.mounted) return;
    final error = await model.setStatus(chosen);
    if (error != null) {
      AppToast.show(error, type: AppToastType.error);
    } else {
      AppToast.show('Status changed');
    }
  }

  /// 9.23 · Make the invite, then show the code and the message to send.
  static Future<void> _invite(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final result = await model.invite();
    if (!context.mounted) return;
    final code = result.code;
    if (code == null) {
      AppToast.show(
        result.error ?? "Couldn't create the invite. Try again.",
        type: AppToastType.error,
      );
      return;
    }
    await _sheet<void>(
      context,
      InviteReadySheet(
        firstName: model.student.firstNameOnly,
        caption: 'Student app code',
        code: code,
        message: model.shareMessage(code),
      ),
    );
  }

  static Future<void> _toggleAccess(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final suspend = model.student.access != StudentAccess.suspended;
    final firstName = model.student.firstNameOnly;
    final done = await AppConfirmSheet.show(
      context,
      icon: suspend ? AppIcons.circlePause : AppIcons.lockOpen,
      tone: suspend ? AppBadgeTone.warning : AppBadgeTone.success,
      title: suspend
          ? "Suspend $firstName's access?"
          : "Restore $firstName's access?",
      message: suspend
          ? "They stay on the student list but can't sign in until you "
                'restore them.'
          : 'They can sign in again to the student app.',
      confirmLabel: suspend ? 'Suspend access' : 'Restore access',
      onConfirm: () => model.setSuspended(suspend),
    );
    if (done == true) {
      AppToast.show(suspend ? 'Access suspended' : 'Access restored');
    }
  }

  static Future<void> _cancelInvite(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final firstName = model.student.firstNameOnly;
    final done = await AppConfirmSheet.show(
      context,
      icon: AppIcons.circleX,
      isDestructive: true,
      title: "Cancel $firstName's invite?",
      message: 'The code stops working. $firstName stays on the student list.',
      confirmLabel: 'Cancel invite',
      onConfirm: model.cancelInvite,
    );
    if (done == true) AppToast.show('Invite cancelled');
  }

  /// 9.24 · Remove: only for a mistake, with what it takes away.
  static Future<void> _remove(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    final removed = await AppConfirmSheet.show(
      context,
      icon: AppIcons.trash2,
      isDestructive: true,
      title: model.removeTitle,
      message: StudentDetailViewModel.removeMessage,
      body: _Bullets(lines: model.removeBullets),
      confirmLabel: 'Remove student',
      cancelLabel: 'Change status instead',
      onConfirm: model.remove,
    );
    if (removed == true) {
      AppToast.show('${model.student.fullName} removed');
      NavigationService.popScreen(true);
    } else if (removed == false && context.mounted) {
      // "Change status instead" is the cancel button: offer it.
      await _changeStatus(context, model);
    }
  }

  // ───────────────────────── parents ─────────────────────────

  /// 9.19 · The Add student flow's own Add a parent sheet. What it adds is
  /// then saved on this student; a failure says so and takes back any photo
  /// that was uploaded for it.
  static Future<void> _addParent(
    BuildContext context,
    StudentDetailViewModel model,
  ) async {
    // Not disposed here: the sheet is still sliding away on its controllers
    // when this resumes, and the model holds nothing but text controllers.
    final sheet = model.parentSheetModel();
    final added = await AddParentSheet.show(context, model: sheet);
    if (!added) return;
    final error = await model.addParentFrom(sheet.parents.last);
    if (error != null) {
      sheet.discardPhotos();
      AppToast.show(error, type: AppToastType.error);
    } else {
      AppToast.show('Parent added');
    }
  }

  /// 9.17 · A parent: call, message, email, change relationship, unlink.
  static void _openParent(
    BuildContext context,
    StudentDetailViewModel model,
    StudentParent parent,
    Color tintFill,
    Color tintInk,
  ) {
    Future<void> launch(Uri uri) async {
      try {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          AppToast.show("Couldn't open that. Try again.", type: AppToastType.error);
        }
      } catch (_) {
        AppToast.show("Couldn't open that. Try again.", type: AppToastType.error);
      }
    }

    AppActionSheet.show(
      context,
      title: parent.displayName,
      subtitle: parent.caption,
      leading: _ParentCircle(parent: parent, fill: tintFill, ink: tintInk),
      tiles: [
        AppSheetTile(
          label: 'Call ${model.phoneLabel(parent.phone)}',
          icon: AppIcons.phone,
          onTap: () => launch(Uri(scheme: 'tel', path: parent.phone)),
        ),
        AppSheetTile(
          label: 'Message',
          icon: AppIcons.messageCircle,
          onTap: () => launch(Uri(scheme: 'sms', path: parent.phone)),
        ),
        if (parent.email != null)
          AppSheetTile(
            label: 'Email',
            icon: AppIcons.mail,
            onTap: () => launch(Uri(scheme: 'mailto', path: parent.email)),
          ),
      ],
      groups: [
        [
          AppSheetAction(
            label: 'View profile',
            icon: AppIcons.user,
            onTap: () => _viewParent(context, model, parent),
          ),
          AppSheetAction(
            label: 'Change relationship',
            icon: AppIcons.pencil,
            onTap: () => _changeRelationship(context, model, parent),
          ),
        ],
        [
          AppSheetAction(
            label: 'Unlink from ${model.student.firstNameOnly}',
            icon: AppIcons.userMinus,
            isDestructive: true,
            onTap: () => _unlink(context, model, parent),
          ),
        ],
      ],
    );
  }

  /// 9.18 · The parent's own page; it pops `true` when something changed, so
  /// this page reloads (a removed parent leaves the list).
  static Future<void> _viewParent(
    BuildContext context,
    StudentDetailViewModel model,
    StudentParent parent,
  ) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: ParentDetailScreen(school: model.school, parentId: parent.id),
    );
    if (changed == true) await model.reload();
  }

  static Future<void> _changeRelationship(
    BuildContext context,
    StudentDetailViewModel model,
    StudentParent parent,
  ) async {
    final chosen = await ParentRelationshipSheet.show(
      context,
      parentName: parent.displayName,
      current: parent.relationship,
    );
    if (chosen == null) return;
    final error = await model.changeRelationship(parent, chosen);
    AppToast.show(
      error ?? 'Relationship changed',
      type: error == null ? AppToastType.success : AppToastType.error,
    );
  }

  /// 9.20
  static Future<void> _unlink(
    BuildContext context,
    StudentDetailViewModel model,
    StudentParent parent,
  ) async {
    final done = await AppConfirmSheet.show(
      context,
      icon: AppIcons.userMinus,
      isDestructive: true,
      title: 'Unlink ${parent.displayName}?',
      message: model.unlinkMessage(parent),
      confirmLabel: 'Unlink',
      cancelLabel: 'Keep them linked',
      onConfirm: () => model.unlink(parent),
    );
    if (done == true) AppToast.show('Parent unlinked');
  }
}

class _Content extends StatelessWidget {
  const _Content({super.key, required this.model});

  final StudentDetailViewModel model;

  StudentProfile get _student => model.student;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _classCard(context),
      _parents(context),
      _details(context),
      if (model.showPersonal) _personal(),
      if (model.showAccess) _access(context),
    ];
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      children: [
        StudentHero(
          student: _student,
          meta: model.identityMeta,
          statusLabel: model.statusLabel,
        ),
        if (model.leftOnLabel case final label?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: _LeftBanner(
              title: label,
              body: model.leftExplanation,
              onChangeStatus: model.canEdit
                  ? () => StudentDetailScreen._changeStatus(context, model)
                  : null,
            ),
          ),
        for (final (index, section) in sections.indexed)
          Padding(
            padding: EdgeInsets.only(
              top: index == 0 && model.leftOnLabel == null
                  ? AppSpacing.lg + AppSpacing.xs
                  : AppSpacing.lg,
            ),
            child: section,
          ),
      ],
    );
  }

  /// Where they sit this session and the subjects they take.
  Widget _classCard(BuildContext context) {
    final placement = _student.placement;
    final editable = model.canChangeClass && placement != null;
    return StaffInfoSection(
      title: 'Class',
      trailing: model.classCaption == null
          ? null
          : AppText(
              model.classCaption!,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: LightColors.textMuted,
              ),
            ),
      rows: [
        StaffTeachingRow(
          key: const ValueKey('student-class'),
          icon: AppIcons.house,
          tileColor: LightColors.primaryPrimaryMute,
          iconColor: LightColors.primaryPrimaryDefault,
          caption: 'Class and arm',
          value: model.classValue,
          showChevron: editable,
          onTap: editable
              ? () => StudentDetailScreen._moveArm(context, model)
              : null,
        ),
        if (placement != null)
          StaffTeachingRow(
            key: const ValueKey('student-subjects'),
            icon: AppIcons.bookOpen,
            tileColor: AppPalette.honeyMute,
            iconColor: AppPalette.honeyText,
            caption: model.subjectsCaption,
            value: model.subjectsValue,
            showChevron: editable && placement.optional.isNotEmpty,
            onTap: editable && placement.optional.isNotEmpty
                ? () => StudentDetailScreen._optionalSubjects(context, model)
                : null,
          ),
      ],
    );
  }

  Widget _parents(BuildContext context) {
    final parents = _student.parents;
    return _Section(
      title: 'Parents',
      action: model.canEdit && _student.isActive
          ? AppSectionAction(
              label: 'Add',
              icon: AppIcons.plus,
              semanticLabel: 'Add a parent',
              onPressed: () => StudentDetailScreen._addParent(context, model),
            )
          : null,
      child: parents.isEmpty
          ? SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  'No parents yet',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LightColors.textDisabled,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, parent) in parents.indexed) ...[
                  if (index > 0) const AppDivider(indent: 0, endIndent: 0),
                  StudentParentRow(
                    key: ValueKey('parent-${parent.id}'),
                    parent: parent,
                    caption: parent.isPrimaryContact
                        ? parent.caption
                        : '${parent.relationship.label} · '
                              '${model.phoneLabel(parent.phone)}',
                    tint: StudentParentRow.tints[
                        index % StudentParentRow.tints.length],
                    onTap: model.canEdit
                        ? () {
                            final tint = StudentParentRow.tints[
                                index % StudentParentRow.tints.length];
                            StudentDetailScreen._openParent(
                              context,
                              model,
                              parent,
                              tint.fill,
                              tint.foreground,
                            );
                          }
                        : null,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _details(BuildContext context) => StaffInfoSection(
    title: 'Details',
    action: model.canEdit
        ? AppSectionAction(
            label: 'Change',
            icon: AppIcons.pencil,
            semanticLabel: 'Change details',
            onPressed: () => StudentDetailScreen._changeDetails(context, model),
          )
        : null,
    rows: [
      StaffInfoRow(
        icon: AppIcons.hash,
        label: 'Admission number',
        value: _student.admissionNumber,
      ),
      StaffInfoRow(
        icon: AppIcons.calendar,
        label: 'Admitted',
        value: model.admittedLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.user,
        label: 'Gender',
        value: _student.gender?.label,
      ),
      StaffInfoRow(
        icon: AppIcons.cake,
        iconOffsetY: -1.5,
        label: 'Date of birth',
        value: model.dateOfBirthLabel,
      ),
    ],
  );

  Widget _personal() => StaffInfoSection(
    title: 'Personal',
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon(AppIcons.lock, size: 13, color: LightColors.textMuted),
        const SizedBox(width: 5),
        AppText(
          'Leaders and their teachers',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: LightColors.textMuted,
          ),
        ),
      ],
    ),
    rows: [
      StaffInfoRow(
        icon: AppIcons.mapPin,
        label: 'State of origin',
        value: model.stateOfOriginLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.house,
        label: 'Home address',
        value: model.address,
        multiline: true,
      ),
      StaffInfoRow(
        icon: AppIcons.droplet,
        label: 'Blood group',
        value: model.bloodGroup,
      ),
      StaffInfoRow(
        icon: AppIcons.dna,
        label: 'Genotype',
        value: model.genotype,
      ),
      StaffInfoRow(
        icon: AppIcons.heartPulse,
        label: 'Medical notes',
        value: model.medicalNotes,
        multiline: true,
      ),
    ],
  );

  /// 9.12 / 9.23 · The student app and what can be done about it. The same
  /// card the staff page uses, with one app and no role.
  Widget _access(BuildContext context) {
    final access = _student.access;
    final hasLogin = access != StudentAccess.notOnApp;
    return AccessCards(
      caption: model.accessCaption,
      apps: model.accessApps(
        onInvite: model.canInvite
            ? () => StudentDetailScreen._invite(context, model)
            : null,
      ),
      actions: [
        AccessAction(
          key: const ValueKey('student-access-status'),
          icon: AppIcons.clock,
          title: 'Change status',
          caption: 'When they graduate, transfer or withdraw.',
          onTap: () => StudentDetailScreen._changeStatus(context, model),
        ),
        if (access == StudentAccess.codeReady && model.canManageAccess)
          AccessAction(
            key: const ValueKey('student-access-cancel'),
            icon: AppIcons.circleX,
            tone: AccessActionTone.warning,
            title: 'Cancel invite',
            caption: 'The code stops working. They stay on the list.',
            onTap: () => StudentDetailScreen._cancelInvite(context, model),
          ),
        if ((access == StudentAccess.onApp ||
                access == StudentAccess.suspended) &&
            model.canManageAccess)
          AccessAction(
            key: const ValueKey('student-access-toggle'),
            icon: access == StudentAccess.suspended
                ? AppIcons.lockOpen
                : AppIcons.circlePause,
            tone: access == StudentAccess.suspended
                ? AccessActionTone.success
                : AccessActionTone.warning,
            title: access == StudentAccess.suspended
                ? 'Restore access'
                : 'Suspend access',
            caption: access == StudentAccess.suspended
                ? 'They can sign in again.'
                : "They stay on the list but can't sign in.",
            onTap: () => StudentDetailScreen._toggleAccess(context, model),
          ),
        if (model.canManageAccess)
          AccessAction(
            key: const ValueKey('student-access-remove'),
            icon: AppIcons.userMinus,
            tone: AccessActionTone.error,
            title: 'Remove student',
            caption: hasLogin
                ? 'Only for a mistake. Also removes their login.'
                : 'Only for a mistake. Removes their records.',
            onTap: () => StudentDetailScreen._remove(context, model),
          ),
      ],
    );
  }
}

/// A titled section whose card holds free-form [child] content.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final AppSectionAction? action;

  @override
  Widget build(BuildContext context) => StaffInfoSection(
    title: title,
    action: action,
    rows: [child],
  );
}

/// 9.22 · The page of a student who has left: when, what it means, and a way
/// back to the status.
class _LeftBanner extends StatelessWidget {
  const _LeftBanner({
    required this.title,
    required this.body,
    required this.onChangeStatus,
  });

  final String title;
  final String body;
  final VoidCallback? onChangeStatus;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppPalette.stone100,
      borderRadius: AppRadius.brCard,
      border: Border.all(color: AppPalette.stone200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: AppIcon(AppIcons.clock, size: 18, color: AppPalette.stone600),
        ),
        const SizedBox(width: AppSpacing.ms),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                style: AppTypography.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LightColors.textStrong,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                body,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: LightColors.textBody,
                ),
              ),
              if (onChangeStatus != null) ...[
                const SizedBox(height: AppSpacing.sm),
                BouncyButton(
                  onPressed: onChangeStatus,
                  child: AppText(
                    'Change status',
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                      color: LightColors.primaryPrimaryText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// The parent's initials in a circle, for the action sheet's header.
class _ParentCircle extends StatelessWidget {
  const _ParentCircle({
    required this.parent,
    required this.fill,
    required this.ink,
  });

  final StudentParent parent;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
    child: AppText(
      parent.initials,
      style: AppTypography.subtitle.copyWith(
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
  );
}

/// What removing a student takes away: a tinted box of three ticked lines.
class _Bullets extends StatelessWidget {
  const _Bullets({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
    decoration: BoxDecoration(
      color: AppPalette.stone50,
      borderRadius: AppRadius.brLg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, line) in lines.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.ms),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(
                AppIcons.circleX,
                size: 18,
                color: LightColors.errorErrorText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  line,
                  style: AppTypography.body.copyWith(
                    height: 20 / 14,
                    color: LightColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

/// The page's skeleton where its content starts.
class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          ScaffoldInsets.bodyTopInsetOf(context),
          AppSpacing.screen,
          0,
        ),
        child: const StaffDetailSkeleton(),
      ),
    ),
  );
}
