import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';

/// A school the signed-in person can open in Hamrash Admin, with every
/// admin-app role they hold there. Several roles at one school add up; there
/// is no role switcher.
class MemberSchool {
  const MemberSchool({
    required this.organization,
    required this.roles,
    this.memberIds = const [],
  });

  final Organization organization;

  /// Highest first: owner, admin, principal, vice principal, bursar.
  final List<OrganizationMemberRole> roles;

  /// This person's membership rows here, one per role. Their staff record
  /// points at one of them.
  final List<String> memberIds;

  String get id => organization.id;
  String get name => organization.name;

  /// "Owner · Principal".
  String get rolesLabel => roles.map((role) => role.displayName).join(' · ');

  bool get isPaused => organization.status == OrganizationStatus.suspended;

  /// Owners and admins edit the school's details and run the setup checklist.
  bool get canManage =>
      roles.contains(OrganizationMemberRole.owner) ||
      roles.contains(OrganizationMemberRole.admin);

  bool get needsDetailsCheck =>
      canManage && organization.detailsConfirmedAt == null;

  /// Active admin-app memberships grouped by school. Archived schools and
  /// non-admin roles are left out. Sorted by name.
  static List<MemberSchool> fromMemberships(
    List<OrganizationMember> memberships,
  ) {
    final bySchool =
        <
          String,
          ({
            Organization org,
            Set<OrganizationMemberRole> roles,
            List<String> memberIds,
          })
        >{};
    for (final member in memberships) {
      final org = member.organization;
      if (org == null ||
          org.status == OrganizationStatus.archived ||
          member.status != OrganizationMemberStatus.active ||
          !member.role.isAdminAppRole) {
        continue;
      }
      bySchool.putIfAbsent(org.id, () => (org: org, roles: {}, memberIds: []))
        ..roles.add(member.role)
        ..memberIds.add(member.id);
    }

    return [
      for (final entry in bySchool.values)
        MemberSchool(
          organization: entry.org,
          memberIds: List.unmodifiable(entry.memberIds),
          roles: OrganizationMemberRole.values
              .where(entry.roles.contains)
              .toList(growable: false),
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
