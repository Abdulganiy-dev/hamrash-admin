import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/change_details_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/contact_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/invite_ready_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/invite_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/role_picker_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_access_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_danger_action.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_identity.dart';
import 'package:hamrash_admin/views/team/widgets/staff_details_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_invite_card.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';
import 'package:stacked/stacked.dart';

/// 8.4, 8.9, 8.10 · One staff member. The page is the same in all three
/// states; where their login has got to decides what it offers. Pops `true`
/// when something was saved.
class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({
    super.key,
    required this.school,
    required this.staffId,
  });

  final MemberSchool school;
  final String staffId;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<StaffDetailViewModel>.reactive(
        viewModelBuilder: () =>
            StaffDetailViewModel(school: school, staffId: staffId),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final content = model.error == null && !model.loading
              ? _Content(model: model)
              : null;
          return DefaultScaffold(
            title: 'Staff',
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(model.changed),
            backgroundColor: AppPalette.linen,
            body:
                content ??
                (model.error != null
                    ? LoadErrorView(onRetry: model.load)
                    : const _Loading()),
            bottomNavigationBar: content != null && model.showDanger
                ? _DangerBar(
                    label: model.dangerLabel,
                    caption: model.dangerCaption,
                    onPressed: model.isPending
                        ? () => content._cancelInvite(context)
                        : () => content._remove(context),
                  )
                : null,
            // The footer draws its own top hairline.
            bottomBarFade: false,
          );
        },
      );
}

class _Content extends StatelessWidget {
  const _Content({required this.model});

  final StaffDetailViewModel model;

  StaffMember get _member => model.member;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[
      StaffDetailIdentity(
        member: _member,
        access: model.access,
        meta: model.identityMeta,
        onContact: () => _contact(context),
      ),
      if (model.isNotOnApp) _noLogin(context),
      if (model.isPending) _pending(context),
      _details(context),
      if (model.showAccess) _access(context),
    ];

    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.ms,
        AppSpacing.md,
        AppSpacing.ms,
      ),
      children: _spaced(blocks),
    );
  }

  /// A 24px gap between the page's blocks.
  List<Widget> _spaced(List<Widget> blocks) => [
    for (var i = 0; i < blocks.length; i++) ...[
      if (i > 0) const SizedBox(height: AppSpacing.lg),
      blocks[i],
    ],
  ];

  /// 8.4 · Nothing to sign in with yet.
  Widget _noLogin(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (model.canInvite) ...[
        AppPrimaryButton(
          size: AppButtonSize.large,
          onPressed: () => _invite(context),
          child: const Text('Invite to Hamrash'),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      AppText(
        'They get a code to join. It never expires.',
        style: AppTypography.body.copyWith(
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w600,
          color: LightColors.textBody,
        ),
      ),
    ],
  );

  /// 8.9 · The code is made; nobody has used it.
  Widget _pending(BuildContext context) => StaffInviteCard(
    code: model.displayCode,
    onTap: () => _openInvite(context),
  );

  Widget _details(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        key: const ValueKey('details-header'),
        height: 44,
        child: Row(
          children: [
            const Expanded(child: _SectionTitle('Details')),
            if (model.canEditDetails)
              AppSectionAction(
                label: 'Change',
                icon: AppIcons.pencil,
                semanticLabel: 'Change details',
                onPressed: () => _changeDetails(context),
              ),
          ],
        ),
      ),
      StaffDetailsCard(
        staffNumber: _member.staffNumber,
        staffType: model.staffTypeLabel,
        phone: _member.phone,
        email: _member.email,
      ),
    ],
  );

  /// 8.10 · They have used the code. Access is the only thing left.
  Widget _access(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 44,
        child: Row(
          children: [
            const Expanded(child: _SectionTitle('Access')),
            if (model.joinedCaption case final caption?)
              AppText(
                caption,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LightColors.textMuted,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.ms),
      StaffAccessCard(
        roleLabel: model.role.teamLabel,
        isSuspended: model.isSuspended,
        onChangeRole: () => _changeRole(context),
        onToggleAccess: () => _toggleAccess(context),
      ),
    ],
  );

  Future<T?> _sheet<T>(
    BuildContext context,
    Widget sheet, {
    AppSheetSize size = AppSheetSize.floating,
  }) =>
      Navigator.of(context).push<T>(AppSheetRoute<T>(size: size, child: sheet));

  Future<OrganizationMemberRole?> _pickRole(BuildContext context) =>
      _sheet<OrganizationMemberRole>(
        context,
        RolePickerSheet(
          selected: model.role,
          title: 'Change role',
          lockAdmin: !model.school.canInviteAdmins,
          viewerName: _member.fullName,
          viewerRole: model.school.roles.isEmpty
              ? null
              : model.school.roles.first,
        ),
      );

  /// 8.5 → 8.8 · Create the invite, then show the code and the message.
  Future<void> _invite(BuildContext context) async {
    final code = await _sheet<String>(
      context,
      InviteSheet(
        fullName: _member.fullName,
        initialRole: model.defaultInviteRole,
        lockAdmin: !model.school.canInviteAdmins,
        noteFor: model.inviteNoteFor,
        onCreate: model.invite,
        viewerName: _member.fullName,
        viewerRole: model.school.roles.isEmpty
            ? null
            : model.school.roles.first,
      ),
    );
    if (code == null || !context.mounted) return;

    final role = model.role;
    await _sheet<void>(
      context,
      InviteReadySheet(
        firstName: _member.firstNameOnly,
        role: role,
        code: code,
        message: model.shareMessage(role, code),
      ),
    );
    await model.reload();
  }

  /// 8.8 · The unused invite's full sheet, from the invite card.
  Future<void> _openInvite(BuildContext context) async {
    if (model.rawCode.isEmpty) return;
    await _sheet<void>(
      context,
      InviteReadySheet(
        firstName: _member.firstNameOnly,
        role: model.role,
        code: model.rawCode,
        message: model.currentShareMessage,
      ),
    );
  }

  /// 8.12 · Contact options for this person.
  Future<void> _contact(BuildContext context) => _sheet<void>(
    context,
    ContactSheet(
      firstName: _member.firstNameOnly,
      subtitle: model.contactSubtitle,
      phone: _member.phone,
      email: _member.email,
    ),
  );

  /// 8.11 · Read the whole record, then let a leader change the editable
  /// fields. The role in the sheet applies immediately.
  Future<void> _changeDetails(BuildContext context) async {
    final record = await model.loadEditDetails();
    if (!context.mounted) return;
    if (record == null) {
      AppToast.show(
        "Couldn't load their details. Try again.",
        type: AppToastType.error,
      );
      return;
    }

    final saved = await _sheet<bool>(
      context,
      ChangeDetailsSheet(
        member: record.staff,
        privateDetails: record.privateDetails,
        role: model.role,
        canChangeRole: model.canChangeRoleInSheet,
        lockAdmin: !model.school.canInviteAdmins,
        viewerName: _member.fullName,
        viewerRole: model.school.roles.isEmpty
            ? null
            : model.school.roles.first,
        onChangeRole: model.isPending
            ? model.changeInviteRole
            : model.changeRole,
        onSave: model.saveDetails,
      ),
    );
    if (saved == true) AppToast.show('Details saved');
  }

  Future<void> _changeRole(BuildContext context) async {
    final role = await _pickRole(context);
    if (role == null || role == model.role) return;
    final error = await model.changeRole(role);
    if (error != null) {
      AppToast.show(error, type: AppToastType.error);
    }
  }

  Future<void> _toggleAccess(BuildContext context) async {
    final suspend = !model.isSuspended;
    final firstName = _member.firstNameOnly;
    final done = await AppConfirmSheet.show(
      context,
      icon: suspend ? AppIcons.circlePause : AppIcons.lockOpen,
      tone: suspend ? AppBadgeTone.warning : AppBadgeTone.success,
      title: suspend
          ? "Suspend $firstName's access?"
          : "Restore $firstName's access?",
      message: suspend
          ? "They stay on the staff list but can't sign in until you restore "
                'them.'
          : 'They can sign in again to the app they already use.',
      confirmLabel: suspend ? 'Suspend access' : 'Restore access',
      onConfirm: () => model.setSuspended(suspend),
    );
    if (done == true) {
      AppToast.show(suspend ? 'Access suspended' : 'Access restored');
    }
  }

  Future<void> _cancelInvite(BuildContext context) async {
    final firstName = _member.firstNameOnly;
    final done = await AppConfirmSheet.show(
      context,
      icon: AppIcons.circleMinus,
      isDestructive: true,
      title: "Cancel $firstName's invite?",
      message: 'The code stops working. $firstName stays on the staff list.',
      confirmLabel: 'Cancel invite',
      onConfirm: model.cancelInvite,
    );
    if (done == true) AppToast.show('Invite cancelled');
  }

  Future<void> _remove(BuildContext context) async {
    final name = _member.fullName;
    final done = await AppConfirmSheet.show(
      context,
      icon: AppIcons.trash2,
      isDestructive: true,
      title: 'Remove $name from the staff list?',
      message: model.isOnApp
          ? 'Their record is removed, and so is their login. They can no '
                'longer sign in.'
          : 'Their record is removed. Nothing else changes.',
      confirmLabel: 'Remove from staff',
      onConfirm: model.remove,
    );
    if (done == true) {
      AppToast.show('$name removed from staff');
      NavigationService.popScreen(true);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => AppText(
    title,
    style: AppTypography.title.copyWith(
      height: 20 / 16,
      fontWeight: FontWeight.w800,
      color: LightColors.textStrong,
    ),
  );
}

/// The pinned action at the bottom of the page. It sits in the scaffold's
/// bottom bar, so the SafeArea keeps it clear of the home indicator and the
/// scroll content above never runs behind it.
class _DangerBar extends StatelessWidget {
  const _DangerBar({
    required this.label,
    required this.caption,
    required this.onPressed,
  });

  final String label;
  final String caption;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      border: const Border(top: BorderSide(color: AppPalette.stone200)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.ms,
          AppSpacing.md,
          AppSpacing.ms + AppSpacing.xxs,
        ),
        child: StaffDangerAction(
          label: label,
          caption: caption,
          onPressed: onPressed,
        ),
      ),
    ),
  );
}

/// [StaffDetailSkeleton] where the page's content starts.
class _Loading extends StatelessWidget {
  const _Loading();

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
