import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../api/models/supabase_models/student_model.dart';
import '../../../database/family_realm_service.dart';

/// Reuses the same keyset-cursor pattern as teachers.
class StudentCursor {
  const StudentCursor({required this.lastName, required this.id});
  final String lastName;
  final String id;
}

class StudentPage {
  const StudentPage({required this.students, required this.hasMore});
  final List<StudentModel> students;
  final bool hasMore;
}

/// The full family for one student — student + their links + their parents.
/// Returned by [StudentService.fetchStudentWithFamily] so the cache write
/// is one atomic chunk.
class StudentFamily {
  const StudentFamily({
    required this.student,
    required this.links,
    required this.parents,
  });
  final StudentModel student;
  final List<StudentParentLink> links;
  final List<ParentModel> parents;
}

/// Supabase + Realm for `public.students` and related tables.
///
/// List fetch: keyset pagination via `fetch_students_page` RPC (online-first,
/// Realm fallback on first page when offline).
/// Mutations: write-through to [FamilyRealmService].
class StudentService {
  StudentService({required FamilyRealmService familyRealmService})
      : _family = familyRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final FamilyRealmService _family;

  static const Duration _timeout = Duration(seconds: 15);

  // ─── List + pagination ──────────────────────────────────────────────

  Future<StudentPage> fetchStudentsPage({
    StudentCursor? after,
    int limit = 20,
    String? search,
    String? classId,
  }) async {
    final trimmed = search?.trim();
    final hasSearch = trimmed != null && trimmed.isNotEmpty;
    final isFirstPage = after == null;
    try {
      final response = await _supabase
          .rpc(
            'fetch_students_page',
            params: {
              'p_after_last_name': after?.lastName,
              'p_after_id': after?.id,
              'p_limit': limit,
              'p_search': hasSearch ? trimmed : null,
              'p_class_id': classId,
            },
          )
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map(
            (e) =>
                StudentModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (isFirstPage && !hasSearch && classId == null) {
        await _family.saveStudents(list);
      }

      return StudentPage(students: list, hasMore: list.length == limit);
    } catch (_) {
      if (isFirstPage && !hasSearch && classId == null) {
        final cached = _family.getAllStudents();
        if (cached.isNotEmpty) {
          return StudentPage(
            students:
                cached.map(_family.studentModelFromRealm).toList(),
            hasMore: false,
          );
        }
      }
      rethrow;
    }
  }

  // ─── Single student + family ───────────────────────────────────────

  Future<StudentModel?> fetchStudent(String id) async {
    try {
      final row = await _supabase
          .from('students')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) return null;
      final model = StudentModel.fromJson(Map<String, dynamic>.from(row));
      await _family.saveStudent(model);
      return model;
    } catch (_) {
      final r = _family.getStudent(id);
      return r == null ? null : _family.studentModelFromRealm(r);
    }
  }

  
  Future<StudentFamily?> fetchStudentWithFamily(String studentId) async {
    try {
      final results = await Future.wait([
        _supabase
            .from('students')
            .select()
            .eq('id', studentId)
            .maybeSingle()
            .timeout(_timeout),
        _supabase
            .from('student_parents')
            .select()
            .eq('student_id', studentId)
            .timeout(_timeout),
      ]);
      final studentRow = results[0];
      if (studentRow == null) return null;

      final student =
          StudentModel.fromJson(Map<String, dynamic>.from(studentRow as Map));
      final linkRows = results[1] as List<dynamic>;
      final links = linkRows
          .map(
            (e) => StudentParentLink.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      List<ParentModel> parents = const [];
      if (links.isNotEmpty) {
        final parentIds = links.map((l) => l.parentId).toSet().toList();
        final parentRows = await _supabase
            .from('parents')
            .select()
            .inFilter('id', parentIds)
            .timeout(_timeout);
        parents = (parentRows as List<dynamic>)
            .map(
              (e) =>
                  ParentModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }

      // Write-through: cache everything so offline traversal works.
      await _family.saveStudent(student);
      await _family.saveParents(parents);
      await _family.replaceLinksForStudent(studentId, links);

      return StudentFamily(
        student: student,
        links: links,
        parents: parents,
      );
    } catch (_) {
      // Offline rebuild from cache
      final cachedStudent = _family.getStudent(studentId);
      if (cachedStudent == null) return null;
      final relations = _family.parentsOf(studentId);
      return StudentFamily(
        student: _family.studentModelFromRealm(cachedStudent),
        links: relations.map((r) => r.link).toList(),
        parents: relations.map((r) => r.parent).toList(),
      );
    }
  }

  // ─── Student CRUD ───────────────────────────────────────────────────

  Future<StudentModel> insertStudent(StudentModel model) async {
    final inserted = await _supabase
        .from('students')
        .insert(model.toInsertJson())
        .select()
        .single();
    final result =
        StudentModel.fromJson(Map<String, dynamic>.from(inserted));
    await _family.saveStudent(result);
    return result;
  }

  Future<StudentModel> updateStudent(String id, StudentModel model) async {
    final updated = await _supabase
        .from('students')
        .update(model.toUpdateJson())
        .eq('id', id)
        .select()
        .single();
    final result =
        StudentModel.fromJson(Map<String, dynamic>.from(updated));
    await _family.saveStudent(result);
    return result;
  }

  Future<void> deleteStudent(String id) async {
    await _supabase.from('students').delete().eq('id', id).timeout(_timeout);
    await _family.deleteStudent(id);
  }

  // ─── Student ↔ Parent link management ──────────────────────────────

  Future<StudentParentLink> linkParent({
    required String studentId,
    required String parentId,
    required String relationship,
    bool isPrimary = false,
  }) async {
    final inserted = await _supabase
        .from('student_parents')
        .insert({
          'student_id': studentId,
          'parent_id': parentId,
          'relationship': relationship,
          'is_primary': isPrimary,
        })
        .select()
        .single();
    final link = StudentParentLink.fromJson(
      Map<String, dynamic>.from(inserted),
    );
    await _family.saveStudentParentLinks([link]);
    return link;
  }

  Future<StudentParentLink> updateLink({
    required String linkId,
    String? relationship,
    bool? isPrimary,
  }) async {
    final body = <String, dynamic>{};
    if (relationship != null) body['relationship'] = relationship;
    if (isPrimary != null) body['is_primary'] = isPrimary;
    final updated = await _supabase
        .from('student_parents')
        .update(body)
        .eq('id', linkId)
        .select()
        .single();
    final link = StudentParentLink.fromJson(
      Map<String, dynamic>.from(updated),
    );
    await _family.saveStudentParentLinks([link]);
    return link;
  }

  Future<void> unlinkParent(String linkId) async {
    await _supabase
        .from('student_parents')
        .delete()
        .eq('id', linkId)
        .timeout(_timeout);
    await _family.deleteLink(linkId);
  }

  // ─── Subject enrollment ────────────────────────────────────────────

  Future<List<StudentSubject>> fetchStudentSubjects(String studentId) async {
    final response = await _supabase
        .from('student_subjects')
        .select()
        .eq('student_id', studentId)
        .timeout(_timeout);
    return (response as List<dynamic>)
        .map(
          (e) => StudentSubject.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<StudentSubject> addStudentSubject({
    required String studentId,
    required String subjectId,
  }) async {
    final inserted = await _supabase
        .from('student_subjects')
        .insert({'student_id': studentId, 'subject_id': subjectId})
        .select()
        .single();
    return StudentSubject.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<void> removeStudentSubject(String assignmentId) async {
    await _supabase
        .from('student_subjects')
        .delete()
        .eq('id', assignmentId)
        .timeout(_timeout);
  }

  /// Replaces all subject enrollments for [studentId] with [subjectIds].
  Future<void> setStudentSubjects({
    required String studentId,
    required List<String> subjectIds,
  }) async {
    await _supabase
        .from('student_subjects')
        .delete()
        .eq('student_id', studentId)
        .timeout(_timeout);
    if (subjectIds.isEmpty) return;
    final rows = subjectIds
        .map((sid) => {'student_id': studentId, 'subject_id': sid})
        .toList();
    await _supabase.from('student_subjects').insert(rows).timeout(_timeout);
  }

  // ─── Claim code + clerk binding (admin) ────────────────────────────

  Future<StudentClaimCode?> fetchClaimCode(String studentId) async {
    final row = await _supabase
        .from('student_claim_codes')
        .select()
        .eq('student_id', studentId)
        .maybeSingle()
        .timeout(_timeout);
    if (row == null) return null;
    return StudentClaimCode.fromJson(Map<String, dynamic>.from(row));
  }

  Future<StudentClerkBinding?> fetchClerkBinding(String studentId) async {
    final row = await _supabase
        .from('student_clerk_bindings')
        .select()
        .eq('student_id', studentId)
        .maybeSingle()
        .timeout(_timeout);
    if (row == null) return null;
    return StudentClerkBinding.fromJson(Map<String, dynamic>.from(row));
  }

  /// Admin: clear the binding so the student can re-claim with a fresh code.
  Future<void> deleteClerkBinding(String studentId) async {
    await _supabase
        .from('student_clerk_bindings')
        .delete()
        .eq('student_id', studentId)
        .timeout(_timeout);
  }
}
