import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/student_registration.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A new parent's phone already belongs to a parent in the school. The
/// database refuses rather than merging; the app should reuse that parent.
class ParentAlreadyInSchool extends SupabaseRefusal {
  const ParentAlreadyInSchool(super.message);
}

/// Students and their parents. Registering goes through one RPC
/// (`register_student`, migration 31) so a student is saved completely or
/// not at all.
///
/// Refusals come back as [SupabaseRefusal] with a readable message.
class StudentService {
  StudentService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly = "Only the school's leaders can register students.";

  /// The most students the People list reads in one go.
  static const listLimit = 1000;

  /// The school's active students, A to Z, each with the arm they are in for
  /// [sessionId] (null when there is no current session, so nobody has an
  /// arm). One read of up to [listLimit] students: there is no paged or
  /// searched student list on the server yet.
  Future<List<StudentSummary>> listStudents({
    required String organizationId,
    String? sessionId,
  }) => runRefusable(
    'listStudents',
    () async {
      final rows = await _supabase
          .from('students')
          .select(StudentSummary.columns)
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('last_name')
          .order('first_name')
          .limit(listLimit);
      return [
        for (final row in rows)
          StudentSummary.fromJson(
            Map<String, dynamic>.from(row),
            sessionId: sessionId,
          ),
      ];
    },
    log: (students) => {
      'organization_id': organizationId,
      'count': students.length,
    },
    forbidden: "You don't have access to the students.",
  );

  /// The most rows one phone search reads before they are compared by
  /// digits here.
  static const _searchLimit = 20;

  /// Parents in the school whose phone is [phone], however it was saved
  /// (0803…, 803…, +234 803…). One request: the parent row with the first
  /// names of their children embedded.
  ///
  /// The filter keeps rows whose phone has the same digits in the same
  /// order (anything may sit between them, such as spaces or a +234), then
  /// the digits are compared exactly here. Returns an empty list for a
  /// number that isn't 10 digits after +234.
  Future<List<ParentMatch>> findParentsByPhone({
    required String organizationId,
    required String phone,
  }) => runRefusable(
    'findParentsByPhone',
    () async {
      final digits = PhoneFormat.digitsAfterPrefix(phone);
      if (digits.length != 10) return const <ParentMatch>[];
      final rows = await _supabase
          .from('parents')
          .select(ParentMatch.columns)
          .eq('organization_id', organizationId)
          .ilike('phone', '%${digits.split('').join('%')}')
          .limit(_searchLimit);
      return [
        for (final row in rows)
          if (ParentMatch.fromJson(row) case final match
              when match.phoneDigits == digits)
            match,
      ];
    },
    log: (matches) => {
      'organization_id': organizationId,
      'count': matches.length,
    },
    forbidden: leadersOnly,
  );

  /// Registers a student with their parents, placement and optional
  /// subjects in one transaction. Every refusal migration 31 raises is
  /// returned with its own message; a new parent whose phone is taken comes
  /// back as [ParentAlreadyInSchool].
  Future<RegisteredStudent> registerStudent(StudentRegistration registration) =>
      runRefusable(
        'registerStudent',
        () async {
          try {
            final result = await _supabase.rpc(
              'register_student',
              params: registration.toParams(),
            );
            return RegisteredStudent.fromJson(result as Map<String, dynamic>);
          } on PostgrestException catch (error) {
            final refusal = refusalFor(error);
            if (refusal != null) throw refusal;
            rethrow;
          }
        },
        log: (student) => {
          'student_id': student.id,
          'parents': student.parentIds.length,
          'subjects': student.subjectIds.length,
        },
        forbidden: leadersOnly,
      );

  /// The readable refusal for one of `register_student`'s own errors, or
  /// null for anything else (a dropped connection, a missing function).
  static SupabaseRefusal? refusalFor(PostgrestException error) {
    final message = error.message.trim();
    if (message.isEmpty) return null;
    return switch (error.code) {
      '23505' when message.contains('already a parent') =>
        ParentAlreadyInSchool(message),
      '42501' => const SupabaseRefusal(leadersOnly),
      '22023' ||
      'P0001' ||
      'P0002' ||
      '23505' ||
      '23514' => SupabaseRefusal(message),
      _ => null,
    };
  }
}
