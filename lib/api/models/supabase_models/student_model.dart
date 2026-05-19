/// App model for `public.students`.
class StudentModel {
  const StudentModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.admissionNumber,
    this.admissionDate,
    this.address,
    this.state,
    this.avatarUrl,
    this.avatarUrlId,
    this.fcmToken,
    required this.isActive,
    this.classId,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? admissionNumber;
  final DateTime? admissionDate;
  final String? address;
  final String? state;
  final String? avatarUrl;
  final String? avatarUrlId;
  final String? fcmToken;
  final bool isActive;
  final String? classId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName => '$firstName $lastName';

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: _asString(json['id']),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: _parseDate(json['date_of_birth']),
      admissionNumber: json['admission_number'] as String?,
      admissionDate: _parseDate(json['admission_date']),
      address: json['address'] as String?,
      state: json['state'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarUrlId: json['avatar_url_id'] as String?,
      fcmToken: json['fcm_token'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      classId: _asString(json['class_id']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'date_of_birth': dateOfBirth?.toIso8601String().substring(0, 10),
        'admission_number': admissionNumber,
        'admission_date': admissionDate?.toIso8601String().substring(0, 10),
        'address': address,
        'state': state,
        'avatar_url': avatarUrl,
        'avatar_url_id': avatarUrlId,
        'fcm_token': fcmToken,
        'is_active': isActive,
        'class_id': classId,
      };

  Map<String, dynamic> toUpdateJson() => {
        ...toInsertJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Subset of fields a student is allowed to update on their own row.
  Map<String, dynamic> toSelfUpdateJson() => {
        'phone': phone,
        'gender': gender,
        'address': address,
        'state': state,
        'avatar_url': avatarUrl,
        'avatar_url_id': avatarUrlId,
        'fcm_token': fcmToken,
        'updated_at': DateTime.now().toIso8601String(),
      };

  StudentModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
    String? admissionNumber,
    DateTime? admissionDate,
    String? address,
    String? state,
    String? avatarUrl,
    String? avatarUrlId,
    String? fcmToken,
    bool? isActive,
    String? classId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      address: address ?? this.address,
      state: state ?? this.state,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarUrlId: avatarUrlId ?? this.avatarUrlId,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      classId: classId ?? this.classId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// App model for `public.parents`.
class ParentModel {
  const ParentModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.address,
    this.state,
    this.avatarUrl,
    this.avatarUrlId,
    this.fcmToken,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? address;
  final String? state;
  final String? avatarUrl;
  final String? avatarUrlId;
  final String? fcmToken;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName => '$firstName $lastName';

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: _asString(json['id']),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarUrlId: json['avatar_url_id'] as String?,
      fcmToken: json['fcm_token'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'address': address,
        'state': state,
        'avatar_url': avatarUrl,
        'avatar_url_id': avatarUrlId,
        'fcm_token': fcmToken,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        ...toInsertJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  Map<String, dynamic> toSelfUpdateJson() => {
        'phone': phone,
        'gender': gender,
        'address': address,
        'state': state,
        'avatar_url': avatarUrl,
        'avatar_url_id': avatarUrlId,
        'fcm_token': fcmToken,
        'updated_at': DateTime.now().toIso8601String(),
      };

  ParentModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? gender,
    String? address,
    String? state,
    String? avatarUrl,
    String? avatarUrlId,
    String? fcmToken,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      state: state ?? this.state,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarUrlId: avatarUrlId ?? this.avatarUrlId,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Canonical relationship values for `public.student_parents.relationship`.
abstract class StudentParentRelationship {
  static const String mother = 'mother';
  static const String father = 'father';
  static const String guardian = 'guardian';
  static const String other = 'other';
  static const List<String> all = [mother, father, guardian, other];

  static String display(String value) {
    switch (value) {
      case mother:
        return 'Mother';
      case father:
        return 'Father';
      case guardian:
        return 'Guardian';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

/// Row in `public.student_parents`.
class StudentParentLink {
  const StudentParentLink({
    required this.id,
    required this.studentId,
    required this.parentId,
    required this.relationship,
    required this.isPrimary,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String parentId;
  final String relationship;
  final bool isPrimary;
  final DateTime? createdAt;

  factory StudentParentLink.fromJson(Map<String, dynamic> json) {
    return StudentParentLink(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      parentId: json['parent_id'] as String,
      relationship: json['relationship'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

/// Row in `public.student_subjects`.
class StudentSubject {
  const StudentSubject({
    required this.id,
    required this.studentId,
    required this.subjectId,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String subjectId;
  final DateTime? createdAt;

  factory StudentSubject.fromJson(Map<String, dynamic> json) {
    return StudentSubject(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      subjectId: json['subject_id'] as String,
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

/// Row in `public.student_claim_codes`.
class StudentClaimCode {
  const StudentClaimCode({
    required this.studentId,
    required this.code,
    this.usedAt,
    this.createdAt,
  });

  final String studentId;
  final String code;
  final DateTime? usedAt;
  final DateTime? createdAt;

  factory StudentClaimCode.fromJson(Map<String, dynamic> json) {
    return StudentClaimCode(
      studentId: json['student_id'] as String,
      code: json['code'] as String,
      usedAt: _parseDateTime(json['used_at']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

/// Row in `public.parent_claim_codes`.
class ParentClaimCode {
  const ParentClaimCode({
    required this.parentId,
    required this.code,
    this.usedAt,
    this.createdAt,
  });

  final String parentId;
  final String code;
  final DateTime? usedAt;
  final DateTime? createdAt;

  factory ParentClaimCode.fromJson(Map<String, dynamic> json) {
    return ParentClaimCode(
      parentId: json['parent_id'] as String,
      code: json['code'] as String,
      usedAt: _parseDateTime(json['used_at']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

/// Row in `public.student_clerk_bindings`.
class StudentClerkBinding {
  const StudentClerkBinding({
    required this.studentId,
    required this.clerkId,
    this.boundAt,
  });

  final String studentId;
  final String clerkId;
  final DateTime? boundAt;

  factory StudentClerkBinding.fromJson(Map<String, dynamic> json) {
    return StudentClerkBinding(
      studentId: json['student_id'] as String,
      clerkId: json['clerk_id'] as String,
      boundAt: _parseDateTime(json['bound_at']),
    );
  }
}

/// Row in `public.parent_clerk_bindings`.
class ParentClerkBinding {
  const ParentClerkBinding({
    required this.parentId,
    required this.clerkId,
    this.boundAt,
  });

  final String parentId;
  final String clerkId;
  final DateTime? boundAt;

  factory ParentClerkBinding.fromJson(Map<String, dynamic> json) {
    return ParentClerkBinding(
      parentId: json['parent_id'] as String,
      clerkId: json['clerk_id'] as String,
      boundAt: _parseDateTime(json['bound_at']),
    );
  }
}

// ─── Shared parse helpers ─────────────────────────────────────────────────

String? _asString(dynamic v) {
  if (v == null) return null;
  return v is String ? v : v.toString();
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
