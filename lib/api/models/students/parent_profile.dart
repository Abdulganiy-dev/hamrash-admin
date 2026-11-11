import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';

/// A child of the parent: who they are, where they sit this session, and how
/// the parent is related to them.
class ParentChild {
  const ParentChild({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.relationship,
    required this.isPrimaryContact,
    this.photoUrl,
    this.armLabel,
  });

  final String studentId;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final ParentRelationship relationship;
  final bool isPrimaryContact;

  /// "JSS 1B", or null when they have no class this session.
  final String? armLabel;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
        .toUpperCase();
  }

  /// "JSS 1B · Primary contact", "Primary 4A", or "Primary contact" with no
  /// class.
  String get caption => [?armLabel, if (isPrimaryContact) 'Primary contact']
      .join(' · ');

  /// The `student_parents` row with the child embedded, their placements
  /// included so the current session's arm can be picked out.
  static const columns =
      'relationship,is_primary_contact,'
      'students!student_parents_student_fkey(id,first_name,last_name,photo_url,'
      'student_placements(session_id,'
      'class_arms!student_placements_arm_fkey(name,'
      'classes!class_arms_class_fkey(name))))';

  factory ParentChild.fromJson(
    Map<String, dynamic> json, {
    String? sessionId,
  }) {
    final student = switch (json['students']) {
      final Map value => Map<String, dynamic>.from(value),
      [final Map first, ...] => Map<String, dynamic>.from(first),
      _ => <String, dynamic>{},
    };
    String? armLabel;
    for (final row in (student['student_placements'] as List? ?? const [])) {
      final placement = Map<String, dynamic>.from(row as Map);
      if (placement['session_id'] != sessionId) continue;
      final arm = placement['class_arms'];
      if (arm is! Map) continue;
      final school = arm['classes'];
      final className = school is Map ? school['name'] as String? : null;
      armLabel = className == null
          ? arm['name'] as String
          : fullArmName(className, arm['name'] as String);
      break;
    }
    return ParentChild(
      studentId: student['id'] as String,
      firstName: student['first_name'] as String? ?? '',
      lastName: student['last_name'] as String? ?? '',
      photoUrl: student['photo_url'] as String?,
      relationship: ParentRelationship.values.firstWhere(
        (value) => value.value == json['relationship'],
        orElse: () => ParentRelationship.other,
      ),
      isPrimaryContact: json['is_primary_contact'] as bool? ?? false,
      armLabel: armLabel,
    );
  }
}

/// One parent as their page shows them: the record, private details, login
/// and children.
class ParentProfile {
  const ParentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.title,
    this.altPhone,
    this.email,
    this.occupation,
    this.address,
    this.photoId,
    this.photoUrl,
    this.isActive = true,
    this.memberId,
    this.login,
    this.children = const [],
  });

  final String id;
  final String? title;
  final String firstName;
  final String lastName;
  final String phone;
  final String? altPhone;
  final String? email;
  final String? occupation;
  final String? address;
  final String? photoId;
  final String? photoUrl;
  final bool isActive;
  final String? memberId;
  final StudentLogin? login;
  final List<ParentChild> children;

  String get fullName => '$firstName $lastName'.trim();

  /// "Mrs Halima Yusuf", or the name alone without a title.
  String get displayName => [?title, fullName].join(' ').trim();

  /// The parent row with their login and private details embedded.
  static const columns =
      'id,title,first_name,last_name,phone,alt_phone,photo_id,photo_url,'
      'is_active,member_id,'
      'member:organization_members!parents_member_fkey(${StudentLogin.columns}),'
      'details:parent_private_details!parent_private_details_parent_fkey('
      'email,occupation,address)';

  factory ParentProfile.fromJson(
    Map<String, dynamic> json, {
    List<ParentChild> children = const [],
  }) {
    final member = json['member'];
    final details = switch (json['details']) {
      final Map value => Map<String, dynamic>.from(value),
      [final Map first, ...] => Map<String, dynamic>.from(first),
      _ => const <String, dynamic>{},
    };
    String? text(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return ParentProfile(
      id: json['id'] as String,
      title: text(json['title']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      altPhone: text(json['alt_phone']),
      email: text(details['email']),
      occupation: text(details['occupation']),
      address: text(details['address']),
      photoId: json['photo_id'] as String?,
      photoUrl: text(json['photo_url']),
      isActive: json['is_active'] as bool? ?? true,
      memberId: json['member_id'] as String?,
      login: member is Map
          ? StudentLogin.fromJson(Map<String, dynamic>.from(member))
          : null,
      children: children,
    );
  }

  ParentProfile copyWith({List<ParentChild>? children}) => ParentProfile(
    id: id,
    title: title,
    firstName: firstName,
    lastName: lastName,
    phone: phone,
    altPhone: altPhone,
    email: email,
    occupation: occupation,
    address: address,
    photoId: photoId,
    photoUrl: photoUrl,
    isActive: isActive,
    memberId: memberId,
    login: login,
    children: children ?? this.children,
  );
}

/// What the parent's Change details sheet may change; `update_parent` takes
/// the whole record, so the unchanged fields are here too.
class ParentDetailsChanges {
  const ParentDetailsChanges({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.title,
    this.email,
    this.occupation,
    this.address,
  });

  factory ParentDetailsChanges.of(ParentProfile parent) => ParentDetailsChanges(
    title: parent.title,
    firstName: parent.firstName,
    lastName: parent.lastName,
    phone: parent.phone,
    email: parent.email,
    occupation: parent.occupation,
    address: parent.address,
  );

  final String? title;
  final String firstName;
  final String lastName;

  /// As it will be stored, `+234…`.
  final String phone;
  final String? email;
  final String? occupation;
  final String? address;
}
