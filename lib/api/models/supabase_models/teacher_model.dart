/// App model for `public.teachers`.
class TeacherModel {
  const TeacherModel({
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
    this.homeroomClassId,
    this.homeroomRole,
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
  final String? homeroomClassId;
  final String? homeroomRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName => '$firstName $lastName';

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
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
      homeroomClassId: json['homeroom_class_id'] as String?,
      homeroomRole: json['homeroom_role'] as String?,
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
        'homeroom_class_id': homeroomClassId,
        'homeroom_role': homeroomRole,
      };

  Map<String, dynamic> toUpdateJson() => {
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
        'homeroom_class_id': homeroomClassId,
        'homeroom_role': homeroomRole,
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Subset of fields a teacher is allowed to update on their own row.
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

  TeacherModel copyWith({
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
    String? homeroomClassId,
    String? homeroomRole,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherModel(
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
      homeroomClassId: homeroomClassId ?? this.homeroomClassId,
      homeroomRole: homeroomRole ?? this.homeroomRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    return v is String ? v : v.toString();
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

/// Represents a row in `public.teacher_clerk_bindings`.
class TeacherClerkBinding {
  const TeacherClerkBinding({
    required this.teacherId,
    required this.clerkId,
    this.boundAt,
  });

  final String teacherId;
  final String clerkId;
  final DateTime? boundAt;

  factory TeacherClerkBinding.fromJson(Map<String, dynamic> json) {
    return TeacherClerkBinding(
      teacherId: json['teacher_id'] as String,
      clerkId: json['clerk_id'] as String,
      boundAt: _parseDateTime(json['bound_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

/// Represents a row in `public.teacher_class_subjects`.
class TeacherClassSubject {
  const TeacherClassSubject({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    this.createdAt,
  });

  final String id;
  final String teacherId;
  final String classId;
  final String subjectId;
  final DateTime? createdAt;

  factory TeacherClassSubject.fromJson(Map<String, dynamic> json) {
    return TeacherClassSubject(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      classId: json['class_id'] as String,
      subjectId: json['subject_id'] as String,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
