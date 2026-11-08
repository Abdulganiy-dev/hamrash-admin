import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/invite_code.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 8.4, 8.9, 8.10 · One staff member. Everything about inviting lives here:
/// no login yet → invite, an unused code → share or cancel, a login → change
/// the role, suspend, restore, or remove the record.
///
/// Sheet saves return an error message (null when it worked); confirmed
/// actions throw [AppAlertError] for [AppConfirmSheet]. The message is the
/// database's reason when it refused, see [SupabaseRefusal].
class StaffDetailViewModel extends BaseViewModel {
  StaffDetailViewModel({
    required this.school,
    required this.staffId,
    TeamService? team,
    DateTime Function()? now,
  }) : _team = team ?? locator<TeamService>(),
       _now = now ?? DateTime.now;

  final MemberSchool school;
  final String staffId;
  final TeamService _team;
  final DateTime Function() _now;

  StaffMember? _staff;
  Object? _error;
  bool _changed = false;

  StaffMember get member => _staff!;
  Object? get error => _error;
  bool get loading => _staff == null && _error == null;

  /// Something was saved, so the page behind should reload.
  bool get changed => _changed;

  StaffLogin? get login => _staff?.login;
  StaffAccess get access => member.access;
  OrganizationMemberRole get role => member.role;

  bool get isPending => access == StaffAccess.invitePending;
  bool get isOnApp =>
      access == StaffAccess.onApp || access == StaffAccess.owner;
  bool get isSuspended => access == StaffAccess.suspended;

  /// The owner's own row has no actions: the database keeps the last owner,
  /// and the app never offers to change an owner's role.
  bool get isOwnerRow => login?.role == OrganizationMemberRole.owner;

  bool get isMe => login != null && school.memberIds.contains(login!.id);

  /// Leaders can invite the roles their tier allows.
  bool get canInvite =>
      school.canIssueLogins &&
      !isOwnerRow &&
      member.canBeInvited &&
      access == StaffAccess.notOnApp;

  /// Only the owner and admins change roles and status.
  bool get canManageAccess => school.canManageAccess && !isOwnerRow;

  /// Only the owner and admins remove a record; the owner's own is never
  /// offered.
  bool get canRemove => school.canManageAccess && !isOwnerRow;

  /// The same tiers as inviting: a principal can't cancel an admin's invite.
  bool get canCancelInvite => isPending && school.canInviteRole(role);

  /// "Admin · joined 3 Sep", "Teacher · Staff app", "Owner · you".
  String get identitySubtitle {
    final roleLabel = role.teamLabel;
    if (isOwnerRow) return isMe ? 'Owner · you' : 'Owner';
    if (login == null || isPending) {
      return '$roleLabel · ${role.appLabel}';
    }
    final joined = login!.joinedAt;
    return joined == null
        ? roleLabel
        : '$roleLabel · joined ${AppDateFormat.relative(joined, now: _now())}';
  }

  /// The role the invite sheet starts on, kept inside what the viewer may
  /// issue. An admin job title seen by a principal drops to principal.
  OrganizationMemberRole get defaultInviteRole {
    final preferred = member.role;
    return school.canInviteRole(preferred)
        ? preferred
        : OrganizationMemberRole.principal;
  }

  bool canInviteRole(OrganizationMemberRole role) => school.canInviteRole(role);

  /// "Teachers sign in to the Hamrash staff app with this code. It works
  /// until it's used or you remove the invite. Nothing is sent."
  String inviteNoteFor(OrganizationMemberRole role) =>
      '${role.pluralLabel} sign in to ${role.appInSentence} with this code. '
      "It works until it's used or you remove the invite. Nothing is sent.";

  /// The raw 8 characters, for sharing. Empty when there's no invite.
  String get rawCode => login?.claimCode ?? '';

  /// "K7M2-QX9P", for showing.
  String get displayCode => InviteCode.format(rawCode);

  /// "Invited today", "Invited 5 Nov".
  String get invitedLine => login == null
      ? ''
      : 'Invited ${AppDateFormat.relative(login!.createdAt, now: _now())}';

  /// The message the school shares. The database stores no sign-in provider,
  /// so the text names both, as the join screen does.
  String shareMessage(OrganizationMemberRole role, String code) =>
      "Hi ${member.firstNameOnly}, you've been added to ${school.name} on "
      'Hamrash. Open ${role.appName}, sign in with Apple or Google, and enter '
      '${InviteCode.format(code)}.';

  /// For the pending state: its code and its role.
  String get currentShareMessage => shareMessage(role, rawCode);

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'StaffDetail.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Pull to refresh: keeps the page and rethrows for the error toast.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'StaffDetail.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// After the invite sheet closes: the page is already refreshed.
  Future<void> reload() async {
    await _fetch().catchError((_) {});
    notifyListeners();
  }

  /// Creates (or reissues) the invite at [role]. Returns the raw code, or
  /// the reason it wasn't made.
  Future<({String? code, String? error})> invite(
    OrganizationMemberRole role,
  ) async {
    try {
      final code = await _team.inviteStaff(staffId: staffId, role: role);
      _changed = true;
      await _fetch().catchError((_) {});
      return (code: code, error: null);
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'StaffDetail.invite',
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return (
        code: null,
        error: messageFor(error, "Couldn't create the invite. Try again."),
      );
    } finally {
      notifyListeners();
    }
  }

  /// Changes the role on an unused invite. `invite_staff` updates the same
  /// invite and returns the same code, so it follows the same tiers.
  Future<String?> changeInviteRole(OrganizationMemberRole role) async {
    final result = await invite(role);
    return result.error;
  }

  /// Changes an active login's role. Only owner and admin.
  Future<String?> changeRole(OrganizationMemberRole role) => _save(
    () => _team.changeRole(memberId: login!.id, role: role),
    "Couldn't change the role. Try again.",
    'StaffDetail.changeRole',
  );

  /// Suspends the login, or restores it.
  Future<void> setSuspended(bool suspended) => _act(
    () => _team.setSuspended(memberId: login!.id, suspended: suspended),
    suspended
        ? "Couldn't suspend access. Try again."
        : "Couldn't restore access. Try again.",
  );

  /// Cancels the unused invite. The staff record stays.
  Future<void> cancelInvite() => _act(
    () => _team.cancelInvite(login!.id),
    "Couldn't cancel the invite. Try again.",
  );

  /// Removes the staff record, and its login with it.
  Future<void> remove() => _act(
    () => _team.removeStaff(staffId),
    "Couldn't remove them from the staff list. Try again.",
  );

  Future<String?> _save(
    Future<void> Function() action,
    String fallback,
    String context,
  ) async {
    try {
      await action();
      _changed = true;
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return messageFor(error, fallback);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback, 'StaffDetail.action');
    if (message != null) throw AppAlertError(message);
  }

  Future<void> _fetch() async {
    _staff = await _team.getStaff(staffId);
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
