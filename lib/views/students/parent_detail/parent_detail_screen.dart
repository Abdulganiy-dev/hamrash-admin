import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/students/parent_profile.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/person_detail_skeleton.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/students/parent_detail/parent_change_details_sheet.dart';
import 'package:hamrash_admin/views/students/parent_detail/parent_detail_view_model.dart';
import 'package:hamrash_admin/views/students/student_detail/student_detail_screen.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';
import 'package:hamrash_admin/views/team/widgets/invite_ready_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_status_pill.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_rows.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart' show StaffAccess;
import 'package:stacked/stacked.dart';

/// 9.18 / 9.18a · One parent: their children, details and login. Pops `true`
/// when something was saved or the parent was removed.
class ParentDetailScreen extends StatelessWidget {
  const ParentDetailScreen({
    super.key,
    required this.school,
    required this.parentId,
    this.viewModel,
  });

  final MemberSchool school;
  final String parentId;

  /// For tests: a view model built with fake services.
  final ParentDetailViewModel? viewModel;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<ParentDetailViewModel>.reactive(
        viewModelBuilder: () =>
            viewModel ??
            ParentDetailViewModel(school: school, parentId: parentId),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          title: 'Parent',
          showBackButton: true,
          onBackPressed: () => NavigationService.popScreen(model.changed),
          backgroundColor: AppPalette.linen,
          body: AnimatedSectionContent(
            morphHeight: false,
            child: model.error != null
                ? LoadErrorView(
                    key: const ValueKey('error'),
                    onRetry: model.load,
                  )
                : model.loading
                ? PersonDetailLoading(
                    key: const ValueKey('loading'),
                    skeleton: ParentDetailSkeleton(leader: model.canEdit),
                  )
                : _Content(
                    key: const ValueKey('content'),
                    model: model,
                    school: school,
                  ),
          ),
        ),
      );

  static Future<void> _changeDetails(
    BuildContext context,
    ParentDetailViewModel model,
  ) async {
    final saved = await ParentChangeDetailsSheet.show(
      context,
      parent: model.parent,
      onSave: model.saveDetails,
    );
    if (saved == true) AppToast.show('Details saved');
  }

  static Future<void> _invite(
    BuildContext context,
    ParentDetailViewModel model,
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
    await Navigator.of(context).push<void>(
      AppSheetRoute<void>(
        size: AppSheetSize.floating,
        child: InviteReadySheet(
          firstName: model.parent.firstName,
          caption: 'Student app code',
          code: code,
          message: model.shareMessage(code),
        ),
      ),
    );
  }

  static Future<void> _toggleAccess(
    BuildContext context,
    ParentDetailViewModel model,
  ) async {
    final suspend = model.access != StudentAccess.suspended;
    final first = model.parent.firstName;
    final done = await AppConfirmSheet.show(
      context,
      icon: suspend ? AppIcons.circlePause : AppIcons.lockOpen,
      tone: suspend ? AppBadgeTone.warning : AppBadgeTone.success,
      title: suspend ? "Suspend $first's access?" : "Restore $first's access?",
      message: suspend
          ? "They stay on the list but can't sign in until you restore them."
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
    ParentDetailViewModel model,
  ) async {
    final first = model.parent.firstName;
    final done = await AppConfirmSheet.show(
      context,
      icon: AppIcons.circleX,
      isDestructive: true,
      title: "Cancel $first's invite?",
      message: 'The code stops working. $first stays on the list.',
      confirmLabel: 'Cancel invite',
      onConfirm: model.cancelInvite,
    );
    if (done == true) AppToast.show('Invite cancelled');
  }

  static Future<void> _remove(
    BuildContext context,
    ParentDetailViewModel model,
  ) async {
    final removed = await AppConfirmSheet.show(
      context,
      icon: AppIcons.trash2,
      isDestructive: true,
      title: model.removeTitle,
      message: ParentDetailViewModel.removeMessage,
      body: _Bullets(lines: model.removeBullets),
      confirmLabel: 'Remove parent',
      onConfirm: model.remove,
    );
    if (removed == true) {
      AppToast.show('${model.parent.displayName} removed');
      NavigationService.popScreen(true);
    }
  }
}

class _Content extends StatelessWidget {
  const _Content({super.key, required this.model, required this.school});

  final ParentDetailViewModel model;
  final MemberSchool school;

  ParentProfile get _parent => model.parent;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _children(context),
      _details(context),
      if (model.canEdit) _access(context),
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
        _Hero(model: model),
        for (final (index, section) in sections.indexed)
          Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? AppSpacing.lg + AppSpacing.xs : AppSpacing.lg,
            ),
            child: section,
          ),
      ],
    );
  }

  Widget _children(BuildContext context) => AppSectionCard(
    title: 'Children',
    // Dividers start where the text does: 40 picture + 12 gap.
    dividerIndent: 52,
    children: _parent.children.isEmpty
        ? [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  'No children yet',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LightColors.textDisabled,
                  ),
                ),
              ),
            ),
          ]
        : [
            for (final child in _parent.children)
              _ChildRow(
                key: ValueKey('child-${child.studentId}'),
                child: child,
                onTap: () => _openChild(context, child),
              ),
          ],
  );

  Future<void> _openChild(BuildContext context, ParentChild child) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: StudentDetailScreen(school: school, studentId: child.studentId),
    );
    if (changed == true) await model.refresh().catchError((_) {});
  }

  Widget _details(BuildContext context) => AppSectionCard(
    title: 'Details',
    action: model.canEdit
        ? AppSectionAction(
            label: 'Change',
            icon: AppIcons.pencil,
            semanticLabel: 'Change details',
            onPressed: () => ParentDetailScreen._changeDetails(context, model),
          )
        : null,
    children: [
      StaffInfoRow(
        icon: AppIcons.phone,
        label: 'Phone',
        value: model.phoneLabel,
      ),
      StaffInfoRow(icon: AppIcons.mail, label: 'Email', value: _parent.email),
      StaffInfoRow(
        icon: AppIcons.briefcase,
        label: 'Occupation',
        value: _parent.occupation,
      ),
      StaffInfoRow(
        icon: AppIcons.house,
        label: 'Home address',
        value: _parent.address,
        multiline: true,
      ),
    ],
  );

  Widget _access(BuildContext context) {
    final access = model.access;
    return AccessCards(
      caption: model.accessCaption,
      apps: model.accessApps(
        onInvite: model.canInvite
            ? () => ParentDetailScreen._invite(context, model)
            : null,
      ),
      actions: [
        if (access == StudentAccess.codeReady && model.canManageAccess)
          AccessAction(
            key: const ValueKey('parent-access-cancel'),
            icon: AppIcons.circleX,
            tone: AccessActionTone.warning,
            title: 'Cancel invite',
            caption: 'The code stops working. They stay on the list.',
            onTap: () => ParentDetailScreen._cancelInvite(context, model),
          ),
        if ((access == StudentAccess.onApp ||
                access == StudentAccess.suspended) &&
            model.canManageAccess)
          AccessAction(
            key: const ValueKey('parent-access-toggle'),
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
            onTap: () => ParentDetailScreen._toggleAccess(context, model),
          ),
        if (model.canManageAccess)
          AccessAction(
            key: const ValueKey('parent-access-remove'),
            icon: AppIcons.userMinus,
            tone: AccessActionTone.error,
            title: 'Remove parent',
            caption: _parent.login == null
                ? 'Only for a mistake. Removes their record and their links to '
                      'their children.'
                : 'Only for a mistake. Removes their record, links and login.',
            onTap: () => ParentDetailScreen._remove(context, model),
          ),
      ],
    );
  }
}

/// The top of the page: their photo or initials, name, "Parent of 2 ·
/// Pharmacist" and where their login has got to.
class _Hero extends StatelessWidget {
  const _Hero({required this.model});

  final ParentDetailViewModel model;

  StaffAccess get _staffAccess => switch (model.access) {
    StudentAccess.notOnApp => StaffAccess.notOnApp,
    StudentAccess.codeReady => StaffAccess.invitePending,
    StudentAccess.onApp => StaffAccess.onApp,
    StudentAccess.suspended => StaffAccess.suspended,
  };

  @override
  Widget build(BuildContext context) {
    final parent = model.parent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLeadingPicture(
          leading: AppListLeading.network(
            parent.photoUrl ?? '',
            name: parent.fullName,
          ),
          size: 80,
        ),
        const SizedBox(height: 14),
        AppText(
          parent.displayName,
          textAlign: TextAlign.center,
          style: AppTypography.heading(26, lineHeight: 32).copyWith(
            letterSpacing: -0.39,
            color: LightColors.textStrong,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppText(
          model.identityMeta,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppPalette.stone500,
          ),
        ),
        const SizedBox(height: 10),
        StaffDetailStatusPill(access: _staffAccess),
      ],
    );
  }
}

/// A 68 row: the child's initials, name, "JSS 1B · Primary contact" and a
/// chevron into their page.
class _ChildRow extends StatelessWidget {
  const _ChildRow({super.key, required this.child, required this.onTap});

  final ParentChild child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${child.fullName}. ${child.caption}',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: ColoredBox(
        color: Colors.transparent,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              AppLeadingPicture(
                leading: AppListLeading.network(
                  child.photoUrl ?? '',
                  name: child.fullName,
                ),
                size: 40,
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      child.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: LightColors.textStrong,
                      ),
                    ),
                    if (child.caption.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      AppText(
                        child.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: LightColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: AppIcon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: AppPalette.stone400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

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
