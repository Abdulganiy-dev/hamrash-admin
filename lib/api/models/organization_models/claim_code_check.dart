import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';

enum ClaimCodeStatus {
  ok('ok'),
  notFound('not_found'),
  locked('locked'),
  schoolInactive('school_inactive'),
  alreadyMember('already_member');

  const ClaimCodeStatus(this.value);

  final String value;

  static ClaimCodeStatus fromJson(String value) =>
      ClaimCodeStatus.values.firstWhere(
        (status) => status.value == value,
        orElse:
            () => throw FormatException('Unknown claim code status: $value'),
      );
}

class ClaimCodeCheck {
  const ClaimCodeCheck({
    required this.status,
    this.organizationId,
    this.schoolName,
    this.schoolCode,
    this.schoolAddress,
    this.schoolState,
    this.schoolLogoUrl,
    this.role,
    this.app,
    this.needsName,
    required this.triesLeft,
    this.retryAt,
  });

  final ClaimCodeStatus status;
  final String? organizationId;
  final String? schoolName;
  final String? schoolCode;
  final String? schoolAddress;
  final String? schoolState;
  final String? schoolLogoUrl;
  final OrganizationMemberRole? role;
  final String? app;
  final bool? needsName;
  final int triesLeft;
  final DateTime? retryAt;

  factory ClaimCodeCheck.fromJson(Map<String, dynamic> json) => ClaimCodeCheck(
    status: ClaimCodeStatus.fromJson(json['status'] as String),
    organizationId: json['organization_id'] as String?,
    schoolName: json['school_name'] as String?,
    schoolCode: json['school_code'] as String?,
    schoolAddress: json['school_address'] as String?,
    schoolState: json['school_state'] as String?,
    schoolLogoUrl: json['school_logo_url'] as String?,
    role:
        json['role'] == null
            ? null
            : OrganizationMemberRole.fromJson(json['role'] as String),
    app: json['app'] as String?,
    needsName: json['needs_name'] as bool?,
    triesLeft: (json['tries_left'] as num).toInt(),
    retryAt:
        json['retry_at'] == null
            ? null
            : DateTime.parse(json['retry_at'] as String),
  );
}
