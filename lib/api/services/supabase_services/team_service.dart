import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_details_changes.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The school's staff records and the logins attached to them. Leaders read
/// the list; only the owner and admins change a name's role or status and
/// remove a record.
///
/// Refusals come back as [SupabaseRefusal] with a readable message.
class TeamService {
  TeamService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'the team.';

  static const ownersOnly = 'Only the owner and admins can do this.';

  static const addRefused =
      'Only the owner, admins, the principal and vice principals can add '
      'staff.';

  static const inviteRefused =
      "You can't issue that login. Only the owner or an admin can invite "
      'admins.';

  static const addRoleRefused =
      "You can't give them that role. Only the owner or an admin can add "
      'admins.';

  static const detailsRefused =
      'Only the owner, admins, the principal and vice principals can change '
      'staff details.';

  /// How many staff one page of the list holds.
  static const pageSize = 30;

  /// One page of the school's staff (`list_staff`): the search, filters and
  /// sort run on the server, which also returns the chip counts and the
  /// cursor for the next page. Pass [cursor] from the previous page, and
  /// start again with null when [filter] changes. Rows carry the login but no
  /// private details.
  Future<StaffPage> listStaffPage({
    required String organizationId,
    StaffFilter filter = StaffFilter.initial,
    int limit = pageSize,
    String? cursor,
  }) => _run(
    'listStaffPage',
    () async {
      try {
        final result = await _supabase.rpc(
          'list_staff',
          params: {
            'p_organization_id': organizationId,
            'p_search': filter.trimmedSearch.isEmpty
                ? null
                : filter.trimmedSearch,
            'p_login': filter.login.value,
            'p_roles': filter.roles.isEmpty
                ? null
                : [for (final role in filter.roles) role.value],
            'p_staff_type': filter.staffType.value,
            'p_statuses': filter.statuses.isEmpty
                ? null
                : [for (final status in filter.statuses) status.value],
            'p_sort': filter.sort.value,
            'p_limit': limit,
            'p_cursor': cursor,
          },
        );
        final page = StaffPage.fromJson(
          Map<String, dynamic>.from(result as Map),
        );
        return StaffPage(
          rows: await _withMemberships(organizationId, page.rows),
          nextCursor: page.nextCursor,
          total: page.total,
          counts: page.counts,
        );
      } on PostgrestException catch (error) {
        // The function refuses bad arguments and stale cursors with 22023
        // and a message written for people.
        if (error.code == '22023') throw SupabaseRefusal(error.message);
        rethrow;
      }
    },
    log: (page) => {
      'organization_id': organizationId,
      'count': page.rows.length,
      'total': page.total,
      'has_more': page.nextCursor != null,
    },
  );

  /// One staff record, for the detail page after a change.
  Future<StaffMember> getStaff(String staffId) => _run('getStaff', () async {
    final row = await _supabase
        .from('staff')
        .select('${StaffMember.columns},organization_id')
        .eq('id', staffId)
        .single();
    final details = await _supabase
        .from('staff_private_details')
        .select(StaffPrivateDetails.columns)
        .eq('staff_id', staffId)
        .maybeSingle();
    final staff = StaffMember.fromJson(row).copyWith(
      privateDetails: details == null
          ? null
          : StaffPrivateDetails.fromJson(details),
    );
    final organizationId = row['organization_id'] as String?;
    if (organizationId == null) return staff;
    return (await _withMemberships(organizationId, [staff])).single;
  }, log: (staff) => {'id': staff.id, 'roles': staff.roles.length});

  /// Adds every role each person holds at the school to their row. A person
  /// on the app has one `organization_members` row per role, all with the
  /// same `clerk_user_id`; leaders can read them all (RLS). The login the
  /// staff row points at stays first and the others follow in the order they
  /// were added. If this read fails the rows keep the one login they came
  /// with, so a list or page still opens.
  Future<List<StaffMember>> _withMemberships(
    String organizationId,
    List<StaffMember> rows,
  ) async {
    final people = {for (final person in rows) ?person.login?.clerkUserId};
    if (people.isEmpty) return rows;
    try {
      final result = await _supabase
          .from('organization_members')
          .select(StaffLogin.columns)
          .eq('organization_id', organizationId)
          .inFilter('clerk_user_id', people.toList());
      final byPerson = <String, List<StaffLogin>>{};
      for (final row in result) {
        final login = StaffLogin.fromJson(Map<String, dynamic>.from(row));
        byPerson.putIfAbsent(login.clerkUserId!, () => []).add(login);
      }
      return [
        for (final person in rows)
          if (byPerson[person.login?.clerkUserId] case final held?)
            person.copyWith(memberships: _primaryFirst(person.login!, held))
          else
            person,
      ];
    } catch (_) {
      return rows;
    }
  }

  static List<StaffLogin> _primaryFirst(
    StaffLogin primary,
    List<StaffLogin> held,
  ) {
    final others = [
      for (final login in held)
        if (login.id != primary.id) login,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return [primary, ...others];
  }

  /// The complete staff row and private details, for the Change details
  /// sheet. `update_staff` needs every argument, so the sheet sends all of
  /// these back with only the editable fields changed.
  Future<({StaffMember staff, StaffPrivateDetails privateDetails})>
  getStaffForEditing(String staffId) => _run(
    'getStaffForEditing',
    () async {
      final row = await _supabase
          .from('staff')
          .select(
            'id,first_name,middle_name,last_name,gender,job_title,phone,email,'
            'photo_id,photo_url,staff_number,staff_type,status,created_at,'
            'member_id',
          )
          .eq('id', staffId)
          .single();
      final details = await _supabase
          .from('staff_private_details')
          .select(StaffPrivateDetails.columns)
          .eq('staff_id', staffId)
          .maybeSingle();
      return (
        staff: StaffMember.fromJson(row),
        privateDetails: StaffPrivateDetails.fromJson(details ?? const {}),
      );
    },
    log: (record) => {'id': record.staff.id},
    forbidden: detailsRefused,
  );

  /// Saves the editable staff fields through `update_staff`, sending every
  /// other field from [staff] and [privateDetails] back unchanged.
  Future<StaffMember> updateStaffDetails({
    required StaffMember staff,
    required StaffPrivateDetails privateDetails,
    required StaffDetailsChanges changes,
  }) => _run(
    'updateStaffDetails',
    () async => StaffMember.fromJson(
      await _supabase.rpc(
            'update_staff',
            params: {
              'p_staff_id': staff.id,
              'p_first_name': changes.firstName,
              'p_last_name': changes.lastName,
              'p_middle_name': changes.middleName,
              'p_staff_number': staff.staffNumber,
              'p_gender': changes.gender?.value,
              'p_phone': changes.phone,
              'p_email': changes.email,
              'p_photo_id': staff.photoId,
              'p_photo_url': staff.photoUrl,
              'p_job_title': changes.jobTitle,
              'p_staff_type': changes.staffType,
              'p_status': changes.status.value,
              'p_date_of_birth': _dateOnly(changes.dateOfBirth),
              'p_address': changes.address,
              'p_state_of_origin': changes.stateOfOrigin,
              'p_employment_date': _dateOnly(changes.employmentDate),
              'p_residence_state': changes.residenceState,
              'p_residence_lga': changes.residenceLga,
            },
          )
          as Map<String, dynamic>,
    ),
    log: (staff) => {'id': staff.id},
    forbidden: detailsRefused,
  );

  /// `update_staff` takes dates as `yyyy-MM-dd`.
  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Adds a staff record (`create_staff`), leaving the number to the
  /// database. The person has no login until [inviteStaff] is called.
  Future<StaffMember> createStaff({
    required String organizationId,
    required String firstName,
    required String lastName,
    required String? phone,
    required String? email,
    required String jobTitle,
    required String staffType,
    String? middleName,
    StaffGender? gender,
    DateTime? dateOfBirth,
    DateTime? employmentDate,
    String? stateOfOrigin,
    String? address,
    String? residenceState,
    String? residenceLga,
  }) => _run(
    'createStaff',
    () async => StaffMember.fromJson(
      await _supabase.rpc(
            'create_staff',
            params: {
              'p_organization_id': organizationId,
              'p_first_name': firstName,
              'p_last_name': lastName,
              'p_middle_name': middleName,
              'p_gender': gender?.value,
              'p_date_of_birth': _dateOnly(dateOfBirth),
              'p_phone': phone,
              'p_email': email,
              'p_job_title': jobTitle,
              'p_staff_type': staffType,
              'p_address': address,
              'p_state_of_origin': stateOfOrigin,
              'p_employment_date': _dateOnly(employmentDate),
              'p_residence_state': residenceState,
              'p_residence_lga': residenceLga,
            },
          )
          as Map<String, dynamic>,
    ),
    log: (staff) => {'id': staff.id, 'job_title': staff.jobTitle},
    forbidden: addRefused,
    duplicate: 'That staff number is already used. Try again.',
    invalid: 'Enter a first and last name.',
  );

  /// Creates or reissues this person's invite at [role] and returns the raw
  /// 8-character code. Calling it again before the code is used returns the
  /// same code, and changes the role when it differs.
  Future<String> inviteStaff({
    required String staffId,
    required OrganizationMemberRole role,
  }) => _run(
    'inviteStaff',
    () async =>
        await _supabase.rpc(
              'invite_staff',
              params: {'p_staff_id': staffId, 'p_role': role.value},
            )
            as String,
    log: (_) => {'staff_id': staffId, 'role': role.value},
    forbidden: inviteRefused,
  );

  /// Cancels an unclaimed invite by deleting the membership. The staff
  /// record stays and its `member_id` goes back to null.
  Future<void> cancelInvite(String memberId) => _run(
    'cancelInvite',
    () async {
      final removed = await _supabase
          .from('organization_members')
          .delete()
          .eq('id', memberId)
          .select('id');
      refuseIfNothingChanged(removed, ownersOnly);
    },
    log: (_) => {'member_id': memberId},
    forbidden: ownersOnly,
  );

  /// Changes an active login's role. The database refuses owner changes and
  /// rows the caller can't manage.
  Future<void> changeRole({
    required String memberId,
    required OrganizationMemberRole role,
  }) => _run(
    'changeRole',
    () => _updateMember(memberId, {'role': role.value}),
    log: (_) => {'member_id': memberId, 'role': role.value},
    forbidden: ownersOnly,
    duplicate: 'They already have that role at this school.',
  );

  /// Gives someone already on the app another role at the school
  /// (`add_member_role`): a new active membership with the same sign-in and
  /// no new code. [memberId] is one of their active memberships. The database
  /// refuses the owner role, roles the caller may not add, people who aren't
  /// on the app, and roles they already hold; those reasons come back as
  /// [SupabaseRefusal]s. Returns the new membership.
  Future<StaffLogin> addMemberRole({
    required String memberId,
    required OrganizationMemberRole role,
  }) => _run(
    'addMemberRole',
    () async => StaffLogin.fromJson(
      Map<String, dynamic>.from(
        await _supabase.rpc(
              'add_member_role',
              params: {'p_member_id': memberId, 'p_role': role.value},
            )
            as Map,
      ),
    ),
    log: (login) => {'member_id': memberId, 'role': login.role.value},
    forbidden: addRoleRefused,
  );

  /// Suspends the login (it stays linked, but can't sign in) or restores it.
  /// A person with several roles has one membership per role, so pass all of
  /// them in [memberIds] and the whole login changes together.
  Future<void> setSuspended({
    required List<String> memberIds,
    required bool suspended,
  }) => _run(
    'setSuspended',
    () => _updateMembers(memberIds, {
      'status': suspended
          ? OrganizationMemberStatus.suspended.value
          : OrganizationMemberStatus.active.value,
    }),
    log: (_) => {'member_ids': memberIds, 'suspended': suspended},
    forbidden: ownersOnly,
  );

  /// Removes the staff record. Migration 28's trigger deletes an unclaimed
  /// invite or suspends an active login; an active owner's record is refused.
  Future<void> removeStaff(String staffId) => _run(
    'removeStaff',
    () async {
      final removed = await _supabase
          .from('staff')
          .delete()
          .eq('id', staffId)
          .select('id');
      refuseIfNothingChanged(removed, ownersOnly);
    },
    log: (_) => {'id': staffId},
    forbidden: ownersOnly,
    inUse:
        "This staff member is used by a closed session, so their record can't "
        'be removed.',
  );

  Future<void> _updateMember(String memberId, Map<String, Object?> values) =>
      _updateMembers([memberId], values);

  Future<void> _updateMembers(
    List<String> memberIds,
    Map<String, Object?> values,
  ) async {
    final changed = await _supabase
        .from('organization_members')
        .update(values)
        .inFilter('id', memberIds)
        .select('id');
    refuseIfNothingChanged(changed, ownersOnly);
  }

  Future<T> _run<T>(
    String name,
    Future<T> Function() body, {
    required Map<String, Object?> Function(T result) log,
    String forbidden = leadersOnly,
    String? duplicate,
    String? inUse,
    String? invalid,
  }) => runRefusable(
    name,
    body,
    log: log,
    forbidden: forbidden,
    duplicate: duplicate,
    inUse: inUse,
    invalid: invalid,
  );
}
