import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_type_option.dart';

/// What the school calls a staff member's job. The form offers these six
/// and stores [jobTitle] in `staff.job_title`; "Other staff" is stored as
/// plain "Staff".
///
/// [staffType] is only the default the Add Staff form starts from: a teacher
/// is `teaching`, every other job title is `non_teaching`. The person's own
/// pick wins, since a principal or an admin may also teach.
enum StaffJobTitleOption {
  teacher(
    'Teacher',
    'Teacher',
    StaffTypeOption.teaching,
    OrganizationMemberRole.teacher,
  ),
  bursar(
    'Bursar',
    'Bursar',
    StaffTypeOption.nonTeaching,
    OrganizationMemberRole.bursar,
  ),
  vicePrincipal(
    'Vice principal',
    'Vice principal',
    StaffTypeOption.nonTeaching,
    OrganizationMemberRole.vicePrincipal,
  ),
  principal(
    'Principal',
    'Principal',
    StaffTypeOption.nonTeaching,
    OrganizationMemberRole.principal,
  ),
  admin(
    'Admin',
    'Admin',
    StaffTypeOption.nonTeaching,
    OrganizationMemberRole.admin,
  ),
  otherStaff(
    'Other staff',
    'Staff',
    StaffTypeOption.nonTeaching,
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

  /// The staff type this job title starts the form on.
  final StaffTypeOption staffType;

  /// The login role this job title usually gets, before the viewer's tier
  /// is taken into account.
  final OrganizationMemberRole defaultRole;
}
