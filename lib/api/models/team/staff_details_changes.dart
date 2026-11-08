import 'package:hamrash_admin/api/models/team/staff_member.dart';

/// The staff details the Change details sheet may change. Everything else in
/// `update_staff` comes from the record it was opened with.
class StaffDetailsChanges {
  const StaffDetailsChanges({
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    required this.staffType,
    required this.status,
    required this.phone,
    required this.email,
    this.middleName,
    this.gender,
    this.dateOfBirth,
    this.employmentDate,
    this.stateOfOrigin,
    this.address,
    this.residenceState,
    this.residenceLga,
  });

  final String firstName;
  final String? middleName;
  final String lastName;
  final StaffGender? gender;
  final DateTime? dateOfBirth;
  final String jobTitle;

  /// `teaching` or `non_teaching`.
  final String staffType;

  /// The record's own status, separate from the login.
  final StaffRecordStatus status;

  /// Optional private details.
  final DateTime? employmentDate;
  final String? stateOfOrigin;

  /// The stored international number, e.g. `+2348035550142`.
  final String? phone;
  final String? email;

  /// Where they live. The state and LGA sit beside the free-text address.
  final String? address;
  final String? residenceState;
  final String? residenceLga;
}
