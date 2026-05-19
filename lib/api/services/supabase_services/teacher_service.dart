import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../api/models/supabase_models/teacher_model.dart';
import '../../../database/models/teacher_realm.dart';
import '../../../database/teacher_realm_service.dart';

/// Thrown when assigning a (class, subject) pair that is already owned by
/// another teacher. Message is the human-readable explanation from the DB.
class TeacherAssignmentConflict implements Exception {
  TeacherAssignmentConflict(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Supabase + Realm for `public.teachers` and related join tables.
///
/// List fetch: Pattern 2 (online-first, Realm fallback).
/// Mutations: Pattern 3 (write-through — cache mirrors server response).
class TeacherService {
  TeacherService({required TeacherRealmService teacherRealmService})
      : _teacherRealm = teacherRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final TeacherRealmService _teacherRealm;

  static const Duration _timeout = Duration(seconds: 15);

  // ──────────────────────────── Teachers ────────────────────────────

  Future<List<TeacherModel>> fetchTeachers() async {
    try {
      final response = await _supabase
          .from('teachers')
          .select()
          .order('last_name', ascending: true)
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map(
            (e) =>
                TeacherModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      await _teacherRealm.saveTeachers(list);
      return list;
    } catch (_) {
      final cached = _teacherRealm.getAllTeachers();
      if (cached.isNotEmpty) {
        return cached.map(_fromRealm).toList();
      }
      rethrow;
    }
  }

  Future<TeacherModel> insertTeacher(TeacherModel model) async {
    final inserted = await _supabase
        .from('teachers')
        .insert(model.toInsertJson())
        .select()
        .single();

    final result =
        TeacherModel.fromJson(Map<String, dynamic>.from(inserted));
    await _teacherRealm.saveTeacher(result);
    return result;
  }

  Future<TeacherModel> updateTeacher(String id, TeacherModel model) async {
    final updated = await _supabase
        .from('teachers')
        .update(model.toUpdateJson())
        .eq('id', id)
        .select()
        .single();

    final result =
        TeacherModel.fromJson(Map<String, dynamic>.from(updated));
    await _teacherRealm.saveTeacher(result);
    return result;
  }

  Future<void> deleteTeacher(String id) async {
    await _supabase.from('teachers').delete().eq('id', id).timeout(_timeout);
    await _teacherRealm.deleteTeacher(id);
  }

  // ──────────────────── Teacher–Class–Subject assignments ───────────

  /// Returns all class-subject assignments for [teacherId].
  Future<List<TeacherClassSubject>> fetchTeacherClassSubjects(
    String teacherId,
  ) async {
    final response = await _supabase
        .from('teacher_class_subjects')
        .select()
        .eq('teacher_id', teacherId)
        .timeout(_timeout);

    return (response as List<dynamic>)
        .map(
          (e) => TeacherClassSubject.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  /// Replaces all class-subject slots for [teacherId] with [assignments].
  /// Each entry is a map with 'class_id' and 'subject_id'.
  Future<void> setClassSubjectsForTeacher(
    String teacherId,
    List<({String classId, String subjectId})> assignments,
  ) async {
    await _supabase
        .from('teacher_class_subjects')
        .delete()
        .eq('teacher_id', teacherId)
        .timeout(_timeout);

    if (assignments.isEmpty) return;

    final rows = assignments
        .map(
          (a) => {
            'teacher_id': teacherId,
            'class_id': a.classId,
            'subject_id': a.subjectId,
          },
        )
        .toList();

    await _supabase
        .from('teacher_class_subjects')
        .insert(rows)
        .timeout(_timeout);
  }

  
  Future<TeacherClassSubject> addClassSubjectForTeacher({
    required String teacherId,
    required String classId,
    required String subjectId,
  }) async {
    try {
      final response = await _supabase
          .rpc(
            'assign_teacher_class_subject',
            params: {
              'p_teacher_id': teacherId,
              'p_class_id': classId,
              'p_subject_id': subjectId,
            },
          )
          .timeout(_timeout);

      return TeacherClassSubject.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (e) {
     
      if (e.code == 'P0001') {
        throw TeacherAssignmentConflict(e.message);
      }
      rethrow;
    }
  }

  /// Removes a single assignment row by its [id].
  Future<void> removeClassSubject(String id) async {
    await _supabase
        .from('teacher_class_subjects')
        .delete()
        .eq('id', id)
        .timeout(_timeout);
  }

  // ──────────────────────── Clerk bindings ─────────────────────────

  /// Returns the clerk binding for [teacherId], or null if unclaimed.
  Future<TeacherClerkBinding?> fetchClerkBinding(String teacherId) async {
    final row = await _supabase
        .from('teacher_clerk_bindings')
        .select()
        .eq('teacher_id', teacherId)
        .maybeSingle()
        .timeout(_timeout);

    if (row == null) return null;
    return TeacherClerkBinding.fromJson(Map<String, dynamic>.from(row));
  }

  /// Admin: deletes the binding so the teacher can re-claim with a fresh code.
  Future<void> deleteClerkBinding(String teacherId) async {
    await _supabase
        .from('teacher_clerk_bindings')
        .delete()
        .eq('teacher_id', teacherId)
        .timeout(_timeout);
  }

  // ──────────────────────── Claim codes ────────────────────────────

  /// Returns the claim code row for [teacherId] (admin only).
  Future<TeacherCode?> fetchClaimCode(String teacherId) async {
    final row = await _supabase
        .from('teacher_claim_codes')
        .select('code, used_at, created_at')
        .eq('teacher_id', teacherId)
        .maybeSingle()
        .timeout(_timeout);

    return row != null ? TeacherCode.fromJson(Map<String, dynamic>.from(row)) : null;
  }

  // ──────────────────────────── Helpers ────────────────────────────

  TeacherModel _fromRealm(TeacherRealm r) => TeacherModel(
        id: r.id,
        firstName: r.firstName,
        lastName: r.lastName,
        email: r.email,
        phone: r.phone,
        gender: r.gender,
        address: r.address,
        state: r.state,
        avatarUrl: r.avatarUrl,
        avatarUrlId: r.avatarUrlId,
        fcmToken: r.fcmToken,
        isActive: r.isActive,
        homeroomClassId: r.homeroomClassId,
        homeroomRole: r.homeroomRole,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );
}
