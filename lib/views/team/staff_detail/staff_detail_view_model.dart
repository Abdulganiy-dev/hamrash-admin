import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/invite_code.dart';
import 'package:hamrash_admin/api/models/team/staff_details_changes.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_catalog.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 8.14 – 8.18 · One staff member. Everything about inviting lives here:
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
    ClassStructureService? structure,
    SubjectService? subjects,
  }) : _team = team ?? locator<TeamService>(),
       _structureOverride = structure,
       _subjectsOverride = subjects;

  final MemberSchool school;
  final String staffId;
  final TeamService _team;
  final ClassStructureService? _structureOverride;
  final SubjectService? _subjectsOverride;

  /// This session's classes and subjects for a teaching staff member. Read
  /// after the record, and left empty when that read fails: the rest of the
  /// page doesn't depend on it.
  List<ClassTeacher> _homerooms = const [];
  List<TeachingAssignment> _subjectsTaught = const [];

  StaffMember? _staff;
  Object? _error;
  bool _changed = false;
  ({StaffMember staff, StaffPrivateDetails privateDetails})? _editRecord;

  StaffMember get member => _staff!;
  Object? get error => _error;
  bool get loading => _staff == null && _error == null;

  /// Something was saved, so the page behind should reload.
  bool get changed => _changed;

  StaffLogin? get login => _staff?.login;
  StaffAccess get access => member.access;
  OrganizationMemberRole get role => member.role;

  bool get isNotOnApp => access == StaffAccess.notOnApp;
  bool get isPending => access == StaffAccess.invitePending;
  bool get isOnApp =>
      access == StaffAccess.onApp || access == StaffAccess.owner;
  bool get isSuspended => access == StaffAccess.suspended;

  /// The owner's own row has no actions: the database keeps the last owner,
  /// and the app never offers to change an owner's role.
  bool get isOwnerRow => login?.role == OrganizationMemberRole.owner;

  /// Leaders can invite the roles their tier allows.
  bool get canInvite =>
      school.canIssueLogins &&
      !isOwnerRow &&
      member.canBeInvited &&
      access == StaffAccess.notOnApp;

  /// Only the owner and admins change roles and status.
  bool get canManageAccess => school.canManageAccess && !isOwnerRow;

  /// The Access card belongs to someone a leader may manage. It holds the
  /// role and the actions that change access; the owner's own row never
  /// shows it.
  bool get showAccess => canManageAccess;

  /// Only the owner and admins remove a record; the owner's own is never
  /// offered.
  bool get canRemove => school.canManageAccess && !isOwnerRow;

  /// Teaching setup belongs to teaching staff only. The record must have
  /// loaded first, so the action waits with the page.
  bool get canSetTeaching => _staff?.staffType == 'teaching';

  /// Teaching staff get a card of where they teach this session.
  bool get showTeaching => canSetTeaching;

  /// "2026/27", read with the rows; empty when they have none this session.
  String get teachingSession {
    for (final row in _homerooms) {
      if (row.sessionName.isNotEmpty) return row.sessionName;
    }
    for (final row in _subjectsTaught) {
      if (row.sessionName.isNotEmpty) return row.sessionName;
    }
    return '';
  }

  /// The session and the classes and arms, read the first time either
  /// teaching sheet needs them and kept while this page is open. Refreshing
  /// the page empties it.
  late final TeachingCatalog teachingCatalog = TeachingCatalog(
    organizationId: school.id,
    structure: _structureOverride,
  );

  /// Homeroom rows, lead first.
  List<ClassTeacher> get homerooms => _homerooms;

  /// The subjects this person teaches, each with its class and arm.
  List<TeachingAssignment> get subjectsTaught => _subjectsTaught;

  /// Leaders edit a staff member's own details; the database allows owner,
  /// admin, principal and vice principal.
  bool get canEditDetails => school.canRunSetup;

  /// The Change details sheet's Role row follows the existing role rules:
  /// an unused invite uses the invite tiers; a live login needs an owner or
  /// admin and never the owner's own row.
  bool get canChangeRoleInSheet =>
      isPending ? canCancelInvite : canManageAccess && (isOnApp || isSuspended);

  /// The same tiers as inviting: a principal can't cancel an admin's invite.
  bool get canCancelInvite => isPending && school.canInviteRole(role);

  /// The Role row only exists for a live login.
  bool get showRoleRow => canManageAccess && (isOnApp || isSuspended);

  /// "Teaching" or "Non-teaching", as the details card writes it.
  String get staffTypeLabel =>
      member.staffType == 'teaching' ? 'Teaching' : 'Non-teaching';

  /// "Bursar · Non-teaching": the job title (the role's name when there is
  /// none) and the staff type, under the name.
  String get identityMeta {
    final jobTitle = member.jobTitle?.trim();
    final title = jobTitle == null || jobTitle.isEmpty
        ? role.teamLabel
        : jobTitle;
    return '$title · $staffTypeLabel';
  }

  /// Private details are for leaders only; the page is leaders-only already,
  /// this keeps the guard next to the data.
  bool get showPersonal => school.canRunSetup;

  /// "12 Mar 1991", or null when not added.
  String? get dateOfBirthLabel {
    final date = member.dateOfBirth;
    return date == null ? null : AppDateFormat.dayMonthYear(date);
  }

  String? get genderLabel => member.gender?.label;

  /// "Ikeja, Lagos": LGA then state. Whichever is known when only one is.
  String? get livesInLabel {
    final details = member.privateDetails;
    // "Federal Capital Territory" is too long for the value column.
    final state = details?.residenceState?.trim();
    final parts = [
      details?.residenceLga?.trim(),
      state == 'Federal Capital Territory' ? 'FCT' : state,
    ].whereType<String>().where((part) => part.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  String? get homeAddress {
    final address = member.privateDetails?.address?.trim();
    return address == null || address.isEmpty ? null : address;
  }

  /// "Active", "On leave" or "Exited".
  String get statusLabel => member.status.label;

  /// "12 Mar 1991", or null when not added.
  String? get employmentDateLabel {
    final date = member.privateDetails?.employmentDate;
    return date == null ? null : AppDateFormat.dayMonthYear(date);
  }

  String? get stateOfOrigin {
    final origin = member.privateDetails?.stateOfOrigin?.trim();
    return origin == null || origin.isEmpty ? null : origin;
  }

  /// "Joined 3 Sep 2026", or null when the login has no joined date.
  String? get joinedCaption {
    final joined = login?.joinedAt;
    return joined == null
        ? null
        : 'Joined ${AppDateFormat.dayMonthYear(joined)}';
  }

  /// "Invited 8 Nov", or null when there is no invite.
  ///
  /// TODO(data): the login has no separate invited-at column, so this reads
  /// its created date — the closest record the database keeps. Swap it when
  /// the login exposes the invite's own date.
  String? get invitedCaption {
    final created = login?.createdAt;
    return isPending && created != null
        ? 'Invited ${AppDateFormat.dayMonth(created)}'
        : null;
  }

  /// "Homeroom · Lead teacher", or just "Homeroom" when they have none.
  String get homeroomCaption => _homerooms.isEmpty
      ? 'Homeroom'
      : 'Homeroom · ${_homerooms.first.isLead ? 'Lead teacher' : 'Assistant teacher'}';

  /// Every arm they lead or assist, e.g. "JSS 1A, JSS 2B", or "Not assigned".
  String get homeroomValue => _homerooms.isEmpty
      ? 'Not assigned'
      : _homerooms.map((row) => row.armLabel).join(', ');

  /// "Subjects · 3 this session".
  String get subjectsCaption =>
      'Subjects · ${_subjectsTaught.length} this session';

  /// Every subject they teach this session, e.g. "Maths, Basic Science,
  /// Civic Education"; "None this session" when there are none.
  String get subjectsValue => _subjectsTaught.isEmpty
      ? 'None this session'
      : _subjectsTaught.map((row) => row.subjectName).join(', ');

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
    teachingCatalog.invalidate();
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

  /// True while the Change details sheet is opening or open, so a second tap
  /// on the button does nothing.
  bool openingDetails = false;

  Future<({StaffMember staff, StaffPrivateDetails privateDetails})?>?
  _editPrefetch;

  /// Reads the complete record for the Change details sheet in the
  /// background as soon as the page has loaded, so the sheet opens the moment
  /// the button is tapped instead of after a network round trip.
  void prefetchEditDetails() {
    if (_editRecord != null || _editPrefetch != null) return;
    _editPrefetch = _readEditRecord().whenComplete(() => _editPrefetch = null);
  }

  /// The complete record the Change details sheet needs. Instant when the
  /// prefetch has finished; otherwise waits for it. Null when it couldn't be
  /// read; the page then shows a toast.
  Future<({StaffMember staff, StaffPrivateDetails privateDetails})?>
  loadEditDetails() async {
    if (_editRecord case final ready?) return ready;
    return await (_editPrefetch ?? _readEditRecord());
  }

  /// Whether the sheet's data is ready, so the button can open it with no
  /// wait at all.
  bool get editDetailsReady => _editRecord != null;

  Future<({StaffMember staff, StaffPrivateDetails privateDetails})?>
  _readEditRecord() async {
    try {
      final record = await _team.getStaffForEditing(staffId);
      _editRecord = record;
      return record;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'StaffDetail.loadEditDetails',
        showErrorModal: false,
      );
      return null;
    }
  }

  /// Saves the fields the Change details sheet may change. Returns the
  /// reason it failed, or null when the page has been refreshed.
  Future<String?> saveDetails(StaffDetailsChanges changes) async {
    // A role change inside the sheet refreshes the page and drops the cached
    // record, so read it again rather than failing.
    final record = _editRecord ?? await _readEditRecord();
    if (record == null) return "Couldn't load their details.";
    return _save(
      () => _team.updateStaffDetails(
        staff: record.staff,
        privateDetails: record.privateDetails,
        changes: changes,
      ),
      "Couldn't save the details. Try again.",
      'StaffDetail.saveDetails',
    );
  }

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
    // The cached edit record is stale once the page data changes.
    _editRecord = null;
    prefetchEditDetails();
    await _fetchTeaching();
  }

  /// Two reads, only for teaching staff: their homeroom rows and their
  /// subjects in the current session. The session is joined inside each, so
  /// neither waits on the other or on a session read.
  Future<void> _fetchTeaching() async {
    if (!canSetTeaching) return;
    try {
      final structure = _structureOverride ?? locator<ClassStructureService>();
      final subjects = _subjectsOverride ?? locator<SubjectService>();
      final results = await Future.wait<Object>([
        structure.getStaffHomerooms(
          organizationId: school.id,
          staffId: staffId,
        ),
        subjects.getStaffSubjects(organizationId: school.id, staffId: staffId),
      ]);
      _homerooms = results[0] as List<ClassTeacher>;
      _subjectsTaught = results[1] as List<TeachingAssignment>;
    } catch (_) {
      // Keep what was shown; the Teaching setup sheet reports its own errors.
    }
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
