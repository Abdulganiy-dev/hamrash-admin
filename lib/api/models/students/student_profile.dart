import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';

/// `public.gender`, as a student's record stores it.
enum StudentGender {
  male('male', 'Male'),
  female('female', 'Female');

  const StudentGender(this.value, this.label);

  final String value;
  final String label;

  static StudentGender? fromJson(Object? value) {
    for (final gender in values) {
      if (gender.value == value) return gender;
    }
    return null;
  }
}

/// A student's login, embedded from `organization_members` through
/// `students.member_id`. Null on the profile when they have none.
class StudentLogin {
  const StudentLogin({
    required this.id,
    required this.status,
    required this.createdAt,
    this.claimCode,
    this.joinedAt,
  });

  final String id;
  final OrganizationMemberStatus status;

  /// The raw 8 characters. Shown as `K7M2-QX9P`.
  final String? claimCode;
  final DateTime? joinedAt;
  final DateTime createdAt;

  static const columns = 'id,status,claim_code,joined_at,created_at';

  factory StudentLogin.fromJson(Map<String, dynamic> json) => StudentLogin(
    id: json['id'] as String,
    status: OrganizationMemberStatus.fromJson(json['status'] as String),
    claimCode: json['claim_code'] as String?,
    joinedAt: switch (json['joined_at']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// Where a student's login has got to, as the Access card words it.
enum StudentAccess { notOnApp, codeReady, onApp, suspended }

/// The student's private details row (leaders and their teachers read it).
class StudentPrivateDetails {
  const StudentPrivateDetails({
    this.dateOfBirth,
    this.address,
    this.stateOfOrigin,
    this.lga,
    this.bloodGroup,
    this.genotype,
    this.medicalNotes,
  });

  final DateTime? dateOfBirth;
  final String? address;
  final String? stateOfOrigin;
  final String? lga;
  final String? bloodGroup;
  final String? genotype;
  final String? medicalNotes;

  static const columns =
      'date_of_birth,address,state_of_origin,lga,blood_group,genotype,'
      'medical_notes';

  factory StudentPrivateDetails.fromJson(Map<String, dynamic> json) =>
      StudentPrivateDetails(
        dateOfBirth: switch (json['date_of_birth']) {
          final String value => DateTime.parse(value),
          _ => null,
        },
        address: json['address'] as String?,
        stateOfOrigin: json['state_of_origin'] as String?,
        lga: json['lga'] as String?,
        bloodGroup: json['blood_group'] as String?,
        genotype: json['genotype'] as String?,
        medicalNotes: json['medical_notes'] as String?,
      );
}

/// A parent linked to the student, with how they are related.
class StudentParent {
  const StudentParent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.relationship,
    required this.isPrimaryContact,
    this.title,
    this.email,
    this.photoUrl,
  });

  final String id;
  final String? title;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? photoUrl;
  final ParentRelationship relationship;
  final bool isPrimaryContact;

  String get fullName => '$firstName $lastName'.trim();

  /// "Mrs Halima Yusuf", or the name alone without a title.
  String get displayName => [?title, fullName].join(' ').trim();

  /// "AB" for Abdullahi Bello.
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
        .toUpperCase();
  }

  /// "Mother · Primary contact", or "Father · 0803 112 4455".
  String get caption => isPrimaryContact
      ? '${relationship.label} · Primary contact'
      : '${relationship.label} · ${PhoneFormat.nationalDisplay(phone)}';

  /// The `student_parents` row with the parent embedded.
  static const columns =
      'relationship,is_primary_contact,'
      'parents!student_parents_parent_fkey(id,title,first_name,last_name,'
      'phone,photo_url,'
      'details:parent_private_details!parent_private_details_parent_fkey(email))';

  factory StudentParent.fromJson(Map<String, dynamic> json) {
    final parent = switch (json['parents']) {
      final Map value => Map<String, dynamic>.from(value),
      [final Map first, ...] => Map<String, dynamic>.from(first),
      _ => <String, dynamic>{},
    };
    return StudentParent(
      id: parent['id'] as String,
      title: _text(parent['title']),
      firstName: parent['first_name'] as String? ?? '',
      lastName: parent['last_name'] as String? ?? '',
      phone: parent['phone'] as String? ?? '',
      email: switch (parent['details']) {
        final Map details => _text(details['email']),
        [final Map first, ...] => _text(first['email']),
        _ => null,
      },
      photoUrl: _text(parent['photo_url']),
      relationship: ParentRelationship.values.firstWhere(
        (value) => value.value == json['relationship'],
        orElse: () => ParentRelationship.other,
      ),
      isPrimaryContact: json['is_primary_contact'] as bool? ?? false,
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// One arm the student could move to: how many students it has this session
/// and its lead teacher.
class ArmChoice {
  const ArmChoice({
    required this.armId,
    required this.name,
    required this.className,
    required this.students,
    required this.isActive,
    this.leadTeacher,
  });

  final String armId;
  final String name;
  final String className;
  final int students;
  final bool isActive;
  final String? leadTeacher;

  /// "JSS 1B".
  String get label => fullArmName(className, name);

  /// "30 students · Lead Ibrahim Bello", or "29 students · No lead yet".
  String get caption =>
      '$students ${students == 1 ? 'student' : 'students'} · '
      '${leadTeacher == null ? 'No lead yet' : 'Lead $leadTeacher'}';
}

/// A subject the student's arm offers, and whether it is compulsory.
class StudentSubjectOffer {
  const StudentSubjectOffer({
    required this.subjectId,
    required this.name,
    required this.isCompulsory,
    this.code,
  });

  final String subjectId;
  final String name;
  final String? code;
  final bool isCompulsory;
}

/// Where the student sits this session: the arm and class, its lead teacher
/// and the subjects it offers with the optional ones they chose.
class StudentPlacement {
  const StudentPlacement({
    required this.sessionId,
    required this.sessionName,
    required this.armId,
    required this.armName,
    required this.classId,
    required this.className,
    this.leadTeacher,
    this.offers = const [],
    this.chosenOptionalIds = const {},
  });

  final String sessionId;

  /// "2026/27".
  final String sessionName;
  final String armId;
  final String armName;
  final String classId;
  final String className;

  /// The arm's lead class teacher, "Ibrahim Bello", or null when none.
  final String? leadTeacher;

  /// Every subject the arm offers.
  final List<StudentSubjectOffer> offers;

  /// The optional subjects (ids) the student takes.
  final Set<String> chosenOptionalIds;

  /// "JSS 1B".
  String get armLabel => fullArmName(className, armName);

  Iterable<StudentSubjectOffer> get core =>
      offers.where((offer) => offer.isCompulsory);

  Iterable<StudentSubjectOffer> get optional =>
      offers.where((offer) => !offer.isCompulsory);

  /// The optional subjects they take, in the arm's order.
  List<StudentSubjectOffer> get chosen => [
    for (final offer in optional)
      if (chosenOptionalIds.contains(offer.subjectId)) offer,
  ];
}

/// One student as the profile shows them: the record, private details,
/// login, parents and where they sit this session.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.admissionNumber,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.middleName,
    this.gender,
    this.admissionDate,
    this.photoId,
    this.photoUrl,
    this.memberId,
    this.login,
    this.details = const StudentPrivateDetails(),
    this.placement,
    this.parents = const [],
  });

  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String admissionNumber;
  final StudentGender? gender;
  final DateTime? admissionDate;
  final String? photoId;
  final String? photoUrl;
  final StudentStatusFilter status;
  final DateTime createdAt;

  /// When the record last changed.
  final DateTime? updatedAt;
  final String? memberId;
  final StudentLogin? login;
  final StudentPrivateDetails details;

  /// Null when they have no class this session.
  final StudentPlacement? placement;
  final List<StudentParent> parents;

  /// The student row with its login and private details embedded.
  static const columns =
      'id,first_name,middle_name,last_name,admission_number,gender,'
      'admission_date,photo_id,photo_url,status,created_at,updated_at,member_id,'
      'member:organization_members!students_member_fkey(${StudentLogin.columns}),'
      'details:student_private_details!student_private_details_student_fkey('
      '${StudentPrivateDetails.columns})';

  factory StudentProfile.fromJson(
    Map<String, dynamic> json, {
    StudentPlacement? placement,
    List<StudentParent> parents = const [],
  }) {
    final member = json['member'];
    final details = switch (json['details']) {
      final Map value => Map<String, dynamic>.from(value),
      [final Map first, ...] => Map<String, dynamic>.from(first),
      _ => null,
    };
    return StudentProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      admissionNumber: json['admission_number'] as String,
      gender: StudentGender.fromJson(json['gender']),
      admissionDate: switch (json['admission_date']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      photoId: json['photo_id'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: StudentStatusFilter.values.firstWhere(
        (status) => status.value == json['status'],
        orElse: () => StudentStatusFilter.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: switch (json['updated_at']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      memberId: json['member_id'] as String?,
      login: member is Map
          ? StudentLogin.fromJson(Map<String, dynamic>.from(member))
          : null,
      details: details == null
          ? const StudentPrivateDetails()
          : StudentPrivateDetails.fromJson(details),
      placement: placement,
      parents: parents,
    );
  }

  StudentProfile copyWith({
    StudentPlacement? placement,
    List<StudentParent>? parents,
  }) => StudentProfile(
    id: id,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    admissionNumber: admissionNumber,
    gender: gender,
    admissionDate: admissionDate,
    photoId: photoId,
    photoUrl: photoUrl,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    memberId: memberId,
    login: login,
    details: details,
    placement: placement ?? this.placement,
    parents: parents ?? this.parents,
  );

  String get fullName => '$firstName $lastName'.trim();

  String get firstNameOnly => firstName;

  /// "First Middle Last", middle left out when blank.
  String get fullNameWithMiddle {
    final middle = middleName?.trim() ?? '';
    return [firstName, if (middle.isNotEmpty) middle, lastName].join(' ');
  }

  /// "AY" for Abdullahi Yusuf.
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
        .toUpperCase();
  }

  bool get isActive => status == StudentStatusFilter.active;

  StudentAccess get access {
    final login = this.login;
    if (login == null) return StudentAccess.notOnApp;
    return switch (login.status) {
      OrganizationMemberStatus.invited => StudentAccess.codeReady,
      OrganizationMemberStatus.suspended => StudentAccess.suspended,
      OrganizationMemberStatus.active => StudentAccess.onApp,
    };
  }
}
