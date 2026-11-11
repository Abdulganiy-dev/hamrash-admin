import 'package:hamrash_admin/api/models/students/student_profile.dart';

/// What the Change details sheet may change. `update_student` takes the
/// whole record, so this holds every editable field, the unchanged ones
/// included.
class StudentDetailsChanges {
  const StudentDetailsChanges({
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.gender,
    this.admissionDate,
    this.dateOfBirth,
    this.stateOfOrigin,
    this.lga,
    this.address,
    this.bloodGroup,
    this.genotype,
    this.medicalNotes,
  });

  /// The student's own values, unchanged.
  factory StudentDetailsChanges.of(StudentProfile student) =>
      StudentDetailsChanges(
        firstName: student.firstName,
        middleName: student.middleName,
        lastName: student.lastName,
        gender: student.gender,
        admissionDate: student.admissionDate,
        dateOfBirth: student.details.dateOfBirth,
        stateOfOrigin: student.details.stateOfOrigin,
        lga: student.details.lga,
        address: student.details.address,
        bloodGroup: student.details.bloodGroup,
        genotype: student.details.genotype,
        medicalNotes: student.details.medicalNotes,
      );

  final String firstName;
  final String? middleName;
  final String lastName;
  final StudentGender? gender;
  final DateTime? admissionDate;
  final DateTime? dateOfBirth;
  final String? stateOfOrigin;
  final String? lga;
  final String? address;
  final String? bloodGroup;
  final String? genotype;
  final String? medicalNotes;
}
