import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';

/// What the school calls a staff member's job. The form offers these six
/// and stores [jobTitle] in `staff.job_title`; "Other staff" is stored as
/// plain "Staff".
///
/// `staff_type` is `teaching` only for [teacher]; the database asks for a
/// type and the job title is all the form knows.
enum StaffJobTitleOption {
  teacher('Teacher', 'Teacher', 'teaching', OrganizationMemberRole.teacher),
  bursar('Bursar', 'Bursar', 'non_teaching', OrganizationMemberRole.bursar),
  vicePrincipal(
    'Vice principal',
    'Vice principal',
    'non_teaching',
    OrganizationMemberRole.vicePrincipal,
  ),
  principal(
    'Principal',
    'Principal',
    'non_teaching',
    OrganizationMemberRole.principal,
  ),
  admin('Admin', 'Admin', 'non_teaching', OrganizationMemberRole.admin),
  otherStaff(
    'Other staff',
    'Staff',
    'non_teaching',
    OrganizationMemberRole.staff,
  );

  const StaffJobTitleOption(
    this.label,
    this.jobTitle,
    this.staffType,
    this.defaultRole,
  );

  /// What the picker shows.
  final String label;

  /// What goes in `staff.job_title`.
  final String jobTitle;

  /// `teaching` or `non_teaching`, the values `staff_type` accepts.
  final String staffType;

  /// The login role this job title usually gets, before the viewer's tier
  /// is taken into account.
  final OrganizationMemberRole defaultRole;
}
