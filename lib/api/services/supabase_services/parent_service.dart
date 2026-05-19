import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../api/models/supabase_models/student_model.dart';
import '../../../database/family_realm_service.dart';

class ParentCursor {
  const ParentCursor({required this.lastName, required this.id});
  final String lastName;
  final String id;
}

class ParentPage {
  const ParentPage({required this.parents, required this.hasMore});
  final List<ParentModel> parents;
  final bool hasMore;
}

/// The full family for one parent — the parent + their links + their kids.
class ParentFamily {
  const ParentFamily({
    required this.parent,
    required this.links,
    required this.students,
  });
  final ParentModel parent;
  final List<StudentParentLink> links;
  final List<StudentModel> students;
}

/// Supabase + Realm for `public.parents`.
///
/// List fetch: `fetch_parents_page` RPC, Realm fallback on offline first page.
/// Mutations: write-through to [FamilyRealmService].
class ParentService {
  ParentService({required FamilyRealmService familyRealmService})
      : _family = familyRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final FamilyRealmService _family;

  static const Duration _timeout = Duration(seconds: 15);

  // ─── List + pagination ──────────────────────────────────────────────

  Future<ParentPage> fetchParentsPage({
    ParentCursor? after,
    int limit = 20,
    String? search,
  }) async {
    final trimmed = search?.trim();
    final hasSearch = trimmed != null && trimmed.isNotEmpty;
    final isFirstPage = after == null;
    try {
      final response = await _supabase
          .rpc(
            'fetch_parents_page',
            params: {
              'p_after_last_name': after?.lastName,
              'p_after_id': after?.id,
              'p_limit': limit,
              'p_search': hasSearch ? trimmed : null,
            },
          )
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map(
            (e) =>
                ParentModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (isFirstPage && !hasSearch) {
        await _family.saveParents(list);
      }

      return ParentPage(parents: list, hasMore: list.length == limit);
    } catch (_) {
      if (isFirstPage && !hasSearch) {
        final cached = _family.getAllParents();
        if (cached.isNotEmpty) {
          return ParentPage(
            parents: cached.map(_family.parentModelFromRealm).toList(),
            hasMore: false,
          );
        }
      }
      rethrow;
    }
  }

  // ─── Single parent + family ────────────────────────────────────────

  Future<ParentModel?> fetchParent(String id) async {
    try {
      final row = await _supabase
          .from('parents')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) return null;
      final model = ParentModel.fromJson(Map<String, dynamic>.from(row));
      await _family.saveParent(model);
      return model;
    } catch (_) {
      final r = _family.getParent(id);
      return r == null ? null : _family.parentModelFromRealm(r);
    }
  }

  /// Returns a [ParentFamily] (parent + all their kids + the link rows).
  /// Hits three tables online, falls back to the merged cache offline.
  Future<ParentFamily?> fetchParentWithFamily(String parentId) async {
    try {
      final results = await Future.wait([
        _supabase
            .from('parents')
            .select()
            .eq('id', parentId)
            .maybeSingle()
            .timeout(_timeout),
        _supabase
            .from('student_parents')
            .select()
            .eq('parent_id', parentId)
            .timeout(_timeout),
      ]);
      final parentRow = results[0];
      if (parentRow == null) return null;

      final parent =
          ParentModel.fromJson(Map<String, dynamic>.from(parentRow as Map));
      final linkRows = results[1] as List<dynamic>;
      final links = linkRows
          .map(
            (e) => StudentParentLink.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      List<StudentModel> students = const [];
      if (links.isNotEmpty) {
        final studentIds = links.map((l) => l.studentId).toSet().toList();
        final rows = await _supabase
            .from('students')
            .select()
            .inFilter('id', studentIds)
            .timeout(_timeout);
        students = (rows as List<dynamic>)
            .map(
              (e) =>
                  StudentModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }

      await _family.saveParent(parent);
      await _family.saveStudents(students);
      await _family.saveStudentParentLinks(links);

      return ParentFamily(parent: parent, links: links, students: students);
    } catch (_) {
      final cached = _family.getParent(parentId);
      if (cached == null) return null;
      final relations = _family.studentsOf(parentId);
      return ParentFamily(
        parent: _family.parentModelFromRealm(cached),
        links: relations.map((r) => r.link).toList(),
        students: relations.map((r) => r.student).toList(),
      );
    }
  }

  // ─── Parent CRUD ────────────────────────────────────────────────────

  Future<ParentModel> insertParent(ParentModel model) async {
    final inserted = await _supabase
        .from('parents')
        .insert(model.toInsertJson())
        .select()
        .single();
    final result = ParentModel.fromJson(Map<String, dynamic>.from(inserted));
    await _family.saveParent(result);
    return result;
  }

  Future<ParentModel> updateParent(String id, ParentModel model) async {
    final updated = await _supabase
        .from('parents')
        .update(model.toUpdateJson())
        .eq('id', id)
        .select()
        .single();
    final result = ParentModel.fromJson(Map<String, dynamic>.from(updated));
    await _family.saveParent(result);
    return result;
  }

  Future<void> deleteParent(String id) async {
    await _supabase.from('parents').delete().eq('id', id).timeout(_timeout);
    await _family.deleteParent(id);
  }

  // ─── Claim code + clerk binding (admin) ────────────────────────────

  Future<ParentClaimCode?> fetchClaimCode(String parentId) async {
    final row = await _supabase
        .from('parent_claim_codes')
        .select()
        .eq('parent_id', parentId)
        .maybeSingle()
        .timeout(_timeout);
    if (row == null) return null;
    return ParentClaimCode.fromJson(Map<String, dynamic>.from(row));
  }

  Future<ParentClerkBinding?> fetchClerkBinding(String parentId) async {
    final row = await _supabase
        .from('parent_clerk_bindings')
        .select()
        .eq('parent_id', parentId)
        .maybeSingle()
        .timeout(_timeout);
    if (row == null) return null;
    return ParentClerkBinding.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteClerkBinding(String parentId) async {
    await _supabase
        .from('parent_clerk_bindings')
        .delete()
        .eq('parent_id', parentId)
        .timeout(_timeout);
  }
}
