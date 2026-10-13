import 'package:hamrash_admin/api/models/organization_models/organization.dart';

enum OrganizationMemberRole {
  owner('owner'),
  admin('admin'),
  principal('principal'),
  vicePrincipal('vice_principal'),
  bursar('bursar'),
  teacher('teacher'),
  staff('staff'),
  parent('parent'),
  student('student');

  const OrganizationMemberRole(this.value);

  final String value;

  String get displayName => switch (this) {
    OrganizationMemberRole.vicePrincipal => 'Vice Principal',
    _ => '${name[0].toUpperCase()}${name.substring(1)}',
  };

  bool get isAdminAppRole => switch (this) {
    OrganizationMemberRole.owner ||
    OrganizationMemberRole.admin ||
    OrganizationMemberRole.principal ||
    OrganizationMemberRole.vicePrincipal ||
    OrganizationMemberRole.bursar => true,
    _ => false,
  };

  static OrganizationMemberRole fromJson(String value) =>
      OrganizationMemberRole.values.firstWhere(
        (role) => role.value == value,
        orElse: () =>
            throw FormatException('Unknown organization member role: $value'),
      );
}

enum OrganizationMemberStatus {
  invited('invited'),
  active('active'),
  suspended('suspended');

  const OrganizationMemberStatus(this.value);

  final String value;

  static OrganizationMemberStatus fromJson(String value) =>
      OrganizationMemberStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () =>
            throw FormatException('Unknown organization member status: $value'),
      );
}

class OrganizationMember {
  const OrganizationMember({
    required this.id,
    required this.organizationId,
    this.clerkUserId,
    required this.role,
    required this.status,
    this.claimCode,
    this.invitedBy,
    this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
    this.organization,
  });

  final String id;
  final String organizationId;
  final String? clerkUserId;
  final OrganizationMemberRole role;
  final OrganizationMemberStatus status;
  final String? claimCode;
  final String? invitedBy;
  final DateTime? joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Organization? organization;

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    final organizationJson = json['organization'];

    return OrganizationMember(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      clerkUserId: json['clerk_user_id'] as String?,
      role: OrganizationMemberRole.fromJson(json['role'] as String),
      status: OrganizationMemberStatus.fromJson(json['status'] as String),
      claimCode: json['claim_code'] as String?,
      invitedBy: json['invited_by'] as String?,
      joinedAt: _dateTimeOrNull(json['joined_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      organization: organizationJson == null
          ? null
          : Organization.fromJson(
              Map<String, dynamic>.from(organizationJson as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'clerk_user_id': clerkUserId,
    'role': role.value,
    'status': status.value,
    'claim_code': claimCode,
    'invited_by': invitedBy,
    'joined_at': joinedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'organization': organization?.toJson(),
  };
}

DateTime? _dateTimeOrNull(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
