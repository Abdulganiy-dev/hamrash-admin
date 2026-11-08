import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_details_changes.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
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

  static const detailsRefused =
      'Only the owner, admins, the principal and vice principals can change '
      'staff details.';

  /// Every staff record at the school, with its login and private details
  /// when the caller may read them.
  Future<List<StaffMember>> listStaff(String organizationId) => _run(
    'listStaff',
    () async {
      final rows = await _supabase
          .from('staff')
          .select(StaffMember.columns)
          .eq('organization_id', organizationId)
          .order('first_name')
          .order('last_name');
      final privateRows = await _supabase
          .from('staff_private_details')
          .select('staff_id,${StaffPrivateDetails.columns}')
          .eq('organization_id', organizationId);
      final byStaff = {
        for (final row in privateRows)
          row['staff_id'] as String: StaffPrivateDetails.fromJson(row),
      };
      return [
        for (final row in rows)
          StaffMember.fromJson(
            row,
          ).copyWith(privateDetails: byStaff[row['id'] as String]),
      ];
    },
    log: (staff) => {'organization_id': organizationId, 'count': staff.length},
  );

  /// One staff record, for the detail page after a change.
  Future<StaffMember> getStaff(String staffId) => _run('getStaff', () async {
    final row = await _supabase
        .from('staff')
        .select(StaffMember.columns)
        .eq('id', staffId)
        .single();
    final details = await _supabase
        .from('staff_private_details')
        .select(StaffPrivateDetails.columns)
        .eq('staff_id', staffId)
        .maybeSingle();
    return StaffMember.fromJson(row).copyWith(
      privateDetails: details == null
          ? null
          : StaffPrivateDetails.fromJson(details),
    );
  }, log: (staff) => {'id': staff.id});

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

  /// Suspends a login (it stays linked, but can't sign in) or restores it.
  Future<void> setSuspended({
    required String memberId,
    required bool suspended,
  }) => _run(
    'setSuspended',
    () => _updateMember(memberId, {
      'status': suspended
          ? OrganizationMemberStatus.suspended.value
          : OrganizationMemberStatus.active.value,
    }),
    log: (_) => {'member_id': memberId, 'suspended': suspended},
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

  Future<void> _updateMember(
    String memberId,
    Map<String, Object?> values,
  ) async {
    final changed = await _supabase
        .from('organization_members')
        .update(values)
        .eq('id', memberId)
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
