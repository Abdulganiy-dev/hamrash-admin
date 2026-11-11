import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_icon_label.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_setup_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/change_details_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/invite_ready_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/invite_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/role_picker_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/share_invite.dart';
import 'package:hamrash_admin/views/team/widgets/staff_access_section.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_identity.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';
import 'package:hamrash_admin/views/team/widgets/staff_invite_code_field.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';
import 'package:stacked/stacked.dart';

/// 9.29 – 9.29c · One staff member. The page is the same in every state;
/// where their login has got to decides what it offers. Pops `true` when
/// something was saved.
class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({
    super.key,
    required this.school,
    required this.staffId,
  });

  final MemberSchool school;
  final String staffId;

  /// Either teaching sheet: the homeroom and subject setup. A save closes
  /// the flow, refreshes the page and says what was set.
  Future<void> _openTeaching(
    BuildContext context,
    StaffDetailViewModel model,
  ) async {
    final change = await TeachingSetupSheet.show(
      context,
      school: school,
      staff: model.member,
      catalog: model.teachingCatalog,
      homerooms: model.homerooms,
      assignments: model.subjectsTaught,
    );
    if (change == null || !context.mounted) return;
    await model.reload();
    AppToast.show(switch (change) {
      TeachingChange.homeroom => 'Homeroom set',
      TeachingChange.subject => 'Subject set',
    });
  }

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<StaffDetailViewModel>.reactive(
        viewModelBuilder: () =>
            StaffDetailViewModel(school: school, staffId: staffId),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          return DefaultScaffold(
            title: 'Staff',
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
                  ? const _Loading(key: ValueKey('loading'))
                  : _Content(
                      key: const ValueKey('content'),
                      model: model,
                      openTeaching: _openTeaching,
                    ),
            ),
          );
        },
      );
}

class _Content extends StatelessWidget {
  const _Content({super.key, required this.model, required this.openTeaching});

  final StaffDetailViewModel model;

  /// Opens the teaching setup sheet from either Teaching row.
  final Future<void> Function(BuildContext context, StaffDetailViewModel model)
  openTeaching;

  StaffMember get _member => model.member;

  @override
  Widget build(BuildContext context) {
    // Every section is the same card; only the first one takes the wider
    // gap under the header.
    final sections = <Widget>[
      if (model.showTeaching) _teaching(context),
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
        StaffDetailIdentity(
          member: _member,
          access: model.access,
          meta: model.identityMeta,
        ),
        // One slot for whatever the login allows next: the invite, the unused
        // code, or nothing. One slot means the change morphs instead of
        // jumping.
        AnimatedSectionContent(child: _actionSlot(context)),
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

  /// 9.29a / 9.29b · The block between the identity and the first card: the
  /// invite button and its note, the unused invite's code, or nothing. The key
  /// is the access state — that key change is what drives the crossfade.
  Widget _actionSlot(BuildContext context) {
    if (model.isNotOnApp) {
      return Padding(
        key: ValueKey(model.access),
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: _noLogin(context),
      );
    }
    if (model.isPending) {
      return Padding(
        key: ValueKey(model.access),
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: _pending(context),
      );
    }
    return SizedBox.shrink(key: ValueKey(model.access));
  }

  /// 9.29a · Nothing to sign in with yet: one card row that opens the invite,
  /// its code note underneath the label.
  Widget _noLogin(BuildContext context) {
    final canInvite = model.canInvite;
    return Semantics(
      button: canInvite,
      enabled: canInvite,
      label:
          'Invite staff to Hamrash. They get a code to join. It never expires.',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: AppSpacing.md,
        ),
        onTap: canInvite ? () => _invite(context) : null,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: AppIcon(
                  AppIcons.smartphone,
                  size: 18,
                  color: AppPalette.stone500,
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Invite staff to Hamrash',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: LightColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    AppText(
                      'They get a code to join. It never expires.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: LightColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (canInvite) ...[
                const SizedBox(width: AppSpacing.sm),
                const AppIcon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: AppPalette.stone400,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 9.29b · The code is made; nobody has used it.
  Widget _pending(BuildContext context) => StaffInviteCodeField(
    code: model.rawCode,
    onShare: model.rawCode.isEmpty
        ? null
        : (origin) => shareInvite(model.currentShareMessage, origin: origin),
  );

  Widget _details(BuildContext context) => StaffInfoSection(
    title: 'Details',
    headerKey: const ValueKey('details-header'),
    action: model.canEditDetails
        ? AppSectionAction(
            label: 'Change',
            icon: AppIcons.pencil,
            semanticLabel: 'Change details',
            onPressed: () => _changeDetails(context),
          )
        : null,
    rows: [
      StaffInfoRow(
        icon: AppIcons.hash,
        label: 'Staff number',
        value: _member.staffNumber,
      ),
      StaffInfoRow(
        icon: AppIcons.briefcase,
        label: 'Staff type',
        value: model.staffTypeLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.activity,
        label: 'Status',
        value: model.statusLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.calendar,
        label: 'Employed',
        value: model.employmentDateLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.phone,
        label: 'Phone',
        value: PhoneFormat.nationalDisplay(_member.phone),
      ),
      StaffInfoRow(icon: AppIcons.mail, label: 'Email', value: _member.email),
    ],
  );

  /// Where this person teaches this session. Both rows open the teaching
  /// sheet; a save refreshes the card.
  Widget _teaching(BuildContext context) => StaffInfoSection(
    title: 'Teaching',
    trailing: model.teachingSession.isEmpty
        ? null
        : AppText(
            model.teachingSession,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: LightColors.textMuted,
            ),
          ),
    rows: [
      StaffTeachingRow(
        key: const ValueKey('teaching-homeroom'),
        icon: AppIcons.house,
        tileColor: LightColors.primaryPrimaryMute,
        iconColor: LightColors.primaryPrimaryDefault,
        caption: model.homeroomCaption,
        value: model.homeroomValue,
        onTap: () => openTeaching(context, model),
      ),
      StaffTeachingRow(
        key: const ValueKey('teaching-subjects'),
        icon: AppIcons.bookOpen,
        tileColor: AppPalette.honeyMute,
        iconColor: AppPalette.honeyText,
        caption: model.subjectsCaption,
        value: model.subjectsValue,
        onTap: () => openTeaching(context, model),
      ),
    ],
  );

  /// Private to leaders: the page is leaders-only, and the guard stays.
  Widget _personal() => StaffInfoSection(
    title: 'Personal',
    trailing: AppIconLabel(
      icon: AppIcons.lock,
      label: 'Only leaders see this',
      iconColor: LightColors.textMuted,
      iconSize: 13,
      gap: 5,
      hugContent: true,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: LightColors.textMuted,
      ),
    ),
    rows: [
      StaffInfoRow(
        icon: AppIcons.cake,
        // The cake's mass sits low in its box; lift it onto the label's line.
        iconOffsetY: -1.5,
        label: 'Date of birth',
        value: model.dateOfBirthLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.user,
        label: 'Gender',
        value: model.genderLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.flag,
        label: 'From',
        value: model.stateOfOrigin,
      ),
      StaffInfoRow(
        icon: AppIcons.mapPin,
        label: 'Lives in',
        value: model.livesInLabel,
      ),
      StaffInfoRow(
        icon: AppIcons.house,
        label: 'Home address',
        value: model.homeAddress,
        multiline: true,
      ),
    ],
  );

  /// 9.29 – 9.29b · Who can use the app: the role and the access actions, or
  /// just remove for someone who never had a login.
  Widget _access(BuildContext context) => StaffAccessSection(
    roleLabel: model.role.teamLabel,
    isOnApp: model.isOnApp,
    isPending: model.isPending,
    isSuspended: model.isSuspended,
    joinedCaption: model.joinedCaption,
    invitedCaption: model.invitedCaption,
    onChangeRole: model.showRoleRow ? () => _changeRole(context) : null,
    onToggleAccess: model.canManageAccess ? () => _toggleAccess(context) : null,
    onCancelInvite: model.canCancelInvite ? () => _cancelInvite(context) : null,
    onRemove: model.canRemove ? () => _remove(context) : null,
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

  /// 9.26 → 9.28 · Create the invite, then show the code and the message.
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

  /// 9.30 · Read the whole record, then let a leader change the editable
  /// fields. The role in the sheet applies immediately.
  Future<void> _changeDetails(BuildContext context) async {
    // One tap only: a second tap while the sheet is loading or open is
    // ignored.
    if (model.openingDetails) return;
    model.openingDetails = true;
    try {
      await _openChangeDetails(context);
    } finally {
      model.openingDetails = false;
    }
  }

  Future<void> _openChangeDetails(BuildContext context) async {
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

/// [StaffDetailSkeleton] where the page's content starts.
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
