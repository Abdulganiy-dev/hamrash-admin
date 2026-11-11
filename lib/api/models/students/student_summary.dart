import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';

/// One student as the People list shows them: name, admission number and
/// the arm they are in this session.
class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.admissionNumber,
    this.photoUrl,
    this.armId,
    this.armLabel,
    this.classOrder = 0,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// e.g. `KCL/2026/0003`.
  final String admissionNumber;
  final String? photoUrl;

  /// The arm they are placed in for the session, null when they have none.
  final String? armId;

  /// "JSS 1A" (the class and the arm).
  final String? armLabel;

  /// The class's own order, so JSS 1 sorts before JSS 2.
  final int classOrder;

  String get fullName => '$firstName $lastName'.trim();

  /// "AO" for Adaeze Okonkwo.
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
        .toUpperCase();
  }

  /// The student row with their placements, the arm and its class embedded.
  static const columns =
      'id,first_name,last_name,admission_number,photo_url,'
      'student_placements(session_id,arm_id,'
      'class_arms!student_placements_arm_fkey(name,'
      'classes!class_arms_class_fkey(name,sort_order)))';

  /// [sessionId] picks which placement counts; a student with none in it has
  /// no arm.
  factory StudentSummary.fromJson(
    Map<String, dynamic> json, {
    String? sessionId,
  }) {
    String? armId;
    String? armLabel;
    var classOrder = 0;
    for (final row in (json['student_placements'] as List? ?? const [])) {
      final placement = Map<String, dynamic>.from(row as Map);
      if (placement['session_id'] != sessionId) continue;
      final arm = placement['class_arms'];
      if (arm is! Map) continue;
      final school = arm['classes'];
      final className = school is Map ? school['name'] as String? : null;
      armId = placement['arm_id'] as String?;
      armLabel = className == null
          ? arm['name'] as String?
          : fullArmName(className, arm['name'] as String);
      classOrder = school is Map ? (school['sort_order'] as num).toInt() : 0;
      break;
    }
    return StudentSummary(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      admissionNumber: json['admission_number'] as String,
      photoUrl: json['photo_url'] as String?,
      armId: armId,
      armLabel: armLabel,
      classOrder: classOrder,
    );
  }
}
