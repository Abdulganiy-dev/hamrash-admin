enum OrganizationStatus {
  trial('trial'),
  active('active'),
  suspended('suspended'),
  archived('archived');

  const OrganizationStatus(this.value);

  final String value;

  /// How the status reads in the app. Hamrash calls a suspended school paused.
  String get label => switch (this) {
    OrganizationStatus.trial => 'Trial',
    OrganizationStatus.active => 'Active',
    OrganizationStatus.suspended => 'Paused',
    OrganizationStatus.archived => 'Archived',
  };

  static OrganizationStatus fromJson(String value) =>
      OrganizationStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () =>
            throw FormatException('Unknown organization status: $value'),
      );
}

class Organization {
  const Organization({
    required this.id,
    required this.code,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.state,
    this.logoUrl,
    required this.status,
    required this.createdBy,
    required this.numberPrefix,
    this.logoId,
    this.detailsConfirmedAt,
    this.detailsConfirmedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? state;
  final String? logoUrl;
  final OrganizationStatus status;
  final String createdBy;
  final String numberPrefix;
  final String? logoId;

  /// When the owner tapped "Looks good" on Check your school.
  final DateTime? detailsConfirmedAt;

  /// Clerk user id of whoever confirmed the details.
  final String? detailsConfirmedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    state: json['state'] as String?,
    logoUrl: json['logo_url'] as String?,
    status: OrganizationStatus.fromJson(json['status'] as String),
    createdBy: json['created_by'] as String,
    numberPrefix: json['number_prefix'] as String,
    logoId: json['logo_id'] as String?,
    detailsConfirmedAt: switch (json['details_confirmed_at']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
    detailsConfirmedBy: json['details_confirmed_by'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'state': state,
    'logo_url': logoUrl,
    'status': status.value,
    'created_by': createdBy,
    'number_prefix': numberPrefix,
    'logo_id': logoId,
    'details_confirmed_at': detailsConfirmedAt?.toIso8601String(),
    'details_confirmed_by': detailsConfirmedBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
