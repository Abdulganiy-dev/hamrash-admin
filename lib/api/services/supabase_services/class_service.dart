import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../api/models/supabase_models/class_model.dart';
import '../../../database/class_realm_service.dart';
import '../../../database/subject_realm_service.dart';

/// Supabase + Realm for `public.classes` and `public.subjects`.
///
/// List fetch: Pattern 2 (online-first, Realm fallback).
/// Mutations: Pattern 3 (write-through — cache mirrors server response).
class ClassService {
  ClassService({
    required ClassRealmService classRealmService,
    required SubjectRealmService subjectRealmService,
  })  : _classRealm = classRealmService,
        _subjectRealm = subjectRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final ClassRealmService _classRealm;
  final SubjectRealmService _subjectRealm;

  static const Duration _timeout = Duration(seconds: 15);

  // ──────────────────────────── Classes ────────────────────────────

  Future<List<ClassModel>> fetchClasses() async {
    try {
      final response = await _supabase
          .from('classes')
          .select()
          .order('name', ascending: true)
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map((e) => ClassModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      await _classRealm.saveClasses(list);
      return list;
    } catch (_) {
      final cached = _classRealm.getAllClasses();
      if (cached.isNotEmpty) {
        return cached
            .map(
              (r) => ClassModel(
                id: r.id,
                name: r.name,
                section: r.section,
                isActive: r.isActive,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList();
      }
      rethrow;
    }
  }

  Future<ClassModel> insertClass(ClassModel model) async {
    final inserted = await _supabase
        .from('classes')
        .insert(model.toInsertJson())
        .select()
        .single();

    final result = ClassModel.fromJson(Map<String, dynamic>.from(inserted));
    await _classRealm.saveClass(result);
    return result;
  }

  Future<ClassModel> updateClass(String id, ClassModel model) async {
    final updated = await _supabase
        .from('classes')
        .update(model.toUpdateJson())
        .eq('id', id)
        .select()
        .single();

    final result = ClassModel.fromJson(Map<String, dynamic>.from(updated));
    await _classRealm.saveClass(result);
    return result;
  }

  Future<void> deleteClass(String id) async {
    await _supabase.from('classes').delete().eq('id', id).timeout(_timeout);
    await _classRealm.deleteClass(id);
  }

  // ──────────────────── Class–Subject assignments ───────────────────

  /// Returns subject IDs currently assigned to [classId].
  Future<List<String>> fetchSubjectIdsForClass(String classId) async {
    final response = await _supabase
        .from('class_subjects')
        .select('subject_id')
        .eq('class_id', classId)
        .timeout(_timeout);

    return (response as List<dynamic>)
        .map((e) => e['subject_id'] as String)
        .toList();
  }

  /// Replaces the subject assignment for [classId] with [subjectIds].
  Future<void> setSubjectsForClass(
    String classId,
    List<String> subjectIds,
  ) async {
    await _supabase
        .from('class_subjects')
        .delete()
        .eq('class_id', classId)
        .timeout(_timeout);

    if (subjectIds.isEmpty) return;

    final rows = subjectIds
        .map((sid) => {'class_id': classId, 'subject_id': sid})
        .toList();

    await _supabase.from('class_subjects').insert(rows).timeout(_timeout);
  }

  // ──────────────────────────── Subjects ───────────────────────────

  Future<List<SubjectModel>> fetchSubjects() async {
    try {
      final response = await _supabase
          .from('subjects')
          .select()
          .order('name', ascending: true)
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map(
            (e) => SubjectModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      await _subjectRealm.saveSubjects(list);
      return list;
    } catch (_) {
      final cached = _subjectRealm.getAllSubjects();
      if (cached.isNotEmpty) {
        return cached
            .map(
              (r) => SubjectModel(
                id: r.id,
                name: r.name,
                description: r.description,
                isActive: r.isActive,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList();
      }
      rethrow;
    }
  }

  Future<SubjectModel> insertSubject(SubjectModel model) async {
    final inserted = await _supabase
        .from('subjects')
        .insert(model.toInsertJson())
        .select()
        .single();

    final result =
        SubjectModel.fromJson(Map<String, dynamic>.from(inserted));
    await _subjectRealm.saveSubject(result);
    return result;
  }

  Future<SubjectModel> updateSubject(String id, SubjectModel model) async {
    final updated = await _supabase
        .from('subjects')
        .update(model.toUpdateJson())
        .eq('id', id)
        .select()
        .single();

    final result =
        SubjectModel.fromJson(Map<String, dynamic>.from(updated));
    await _subjectRealm.saveSubject(result);
    return result;
  }

  Future<void> deleteSubject(String id) async {
    await _supabase.from('subjects').delete().eq('id', id).timeout(_timeout);
    await _subjectRealm.deleteSubject(id);
  }
}
