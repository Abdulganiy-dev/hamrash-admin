import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The school's subjects and which arms take them. School leaders change
/// them; everyone else can only read. The database keeps a subject that's
/// taught or chosen by students.
///
/// Refusals come back as [SupabaseRefusal] with a readable message.
class SubjectService {
  SubjectService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'subjects.';

  static const assignmentsLeadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'who teaches what.';

  /// Every subject at the school, in report-card order.
  Future<List<Subject>> listSubjects(String organizationId) => _run(
    'listSubjects',
    () async {
      final rows = await _supabase
          .from('subjects')
          .select(Subject.columns)
          .eq('organization_id', organizationId)
          .order('sort_order')
          .order('name');
      return rows.map(Subject.fromJson).toList();
    },
    log: (subjects) => {
      'organization_id': organizationId,
      'count': subjects.length,
    },
  );

  /// Which subject every arm at the school takes.
  Future<List<ArmSubject>> listArmSubjects(String organizationId) => _run(
    'listArmSubjects',
    () async {
      final rows = await _supabase
          .from('arm_subjects')
          .select(ArmSubject.columns)
          .eq('organization_id', organizationId);
      return rows.map(ArmSubject.fromJson).toList();
    },
    log: (links) => {'organization_id': organizationId, 'count': links.length},
  );

  /// Subjects arms take that are taught or chosen this session, so the app
  /// can say why one can't come off an arm before anyone tries.
  Future<List<ArmSubjectUsage>> listArmSubjectUsage(
    String organizationId,
  ) => _run(
    'listArmSubjectUsage',
    () async {
      final rows = await _supabase.rpc(
        'arm_subject_usage',
        params: {'p_organization_id': organizationId},
      );
      return (rows as List<dynamic>)
          .map((row) => ArmSubjectUsage.fromJson(row as Map<String, dynamic>))
          .toList();
    },
    log: (usage) => {'organization_id': organizationId, 'count': usage.length},
  );

  /// 41 common Nigerian subjects, and the usual list for its level on every
  /// existing arm of a standard-named class. Only for a school with no
  /// subjects yet. Returns how many subjects it made.
  Future<int> createStandardSubjects(String organizationId) => _run(
    'createStandardSubjects',
    () async =>
        await _supabase.rpc(
              'create_standard_subjects',
              params: {'p_organization_id': organizationId},
            )
            as int,
    log: (subjects) => {
      'organization_id': organizationId,
      'subjects': subjects,
    },
  );

  /// Adds a subject at the end of the report card. Returns its id.
  Future<String> addSubject({
    required String organizationId,
    required String name,
    required String? code,
    required int sortOrder,
  }) => _run(
    'addSubject',
    () async {
      final row = await _supabase
          .from('subjects')
          .insert({
            'organization_id': organizationId,
            'name': name,
            'code': code,
            'sort_order': sortOrder,
          })
          .select('id')
          .single();
      return row['id'] as String;
    },
    log: (id) => {'id': id},
    duplicate: _taken(name, code),
  );

  Future<void> updateSubject(
    Subject subject, {
    required String name,
    required String? code,
  }) => _run(
    'updateSubject',
    () => _update(subject.id, {
      if (name != subject.name) 'name': name,
      if (code != subject.code) 'code': code,
    }),
    log: (_) => {'id': subject.id},
    duplicate: _taken(name, code),
  );

  /// Switched-off subjects stay on past records but aren't offered.
  Future<void> setSubjectActive(Subject subject, bool isActive) => _run(
    'setSubjectActive',
    () => _update(subject.id, {'is_active': isActive}),
    log: (_) => {'id': subject.id, 'is_active': isActive},
  );

  /// Removes an unused subject, and takes it off every arm.
  Future<void> deleteSubject(Subject subject) => _run(
    'deleteSubject',
    () async {
      final removed = await _supabase
          .from('subjects')
          .delete()
          .eq('id', subject.id)
          .select('id');
      refuseIfNothingChanged(removed, leadersOnly);
    },
    log: (_) => {'id': subject.id},
    inUse:
        "${subject.name} is taught or chosen by students, so it can't be "
        'removed. Switch it off instead.',
  );

  /// Gives each of [armIds] each of [subjectIds]. Subjects an arm already
  /// takes are left as they are.
  Future<void> addToArms({
    required String organizationId,
    required List<String> armIds,
    required List<String> subjectIds,
    required bool isCompulsory,
  }) => _run('addToArms', () async {
    await _supabase
        .from('arm_subjects')
        .upsert(
          [
            for (final armId in armIds)
              for (final subjectId in subjectIds)
                {
                  'organization_id': organizationId,
                  'arm_id': armId,
                  'subject_id': subjectId,
                  'is_compulsory': isCompulsory,
                },
          ],
          onConflict: 'arm_id,subject_id',
          ignoreDuplicates: true,
        );
  }, log: (_) => {'arms': armIds.length, 'subjects': subjectIds.length});

  /// Makes [subjectId] compulsory or optional in each of [armIds].
  Future<void> setCompulsory({
    required List<String> armIds,
    required String subjectId,
    required bool isCompulsory,
  }) => _run('setCompulsory', () async {
    final changed = await _supabase
        .from('arm_subjects')
        .update({'is_compulsory': isCompulsory})
        .eq('subject_id', subjectId)
        .inFilter('arm_id', armIds)
        .select('arm_id');
    refuseIfNothingChanged(changed, leadersOnly);
  }, log: (_) => {'subject_id': subjectId, 'arms': armIds.length});

  /// Takes [subjectId] off each of [armIds].
  Future<void> removeFromArms({
    required List<String> armIds,
    required String subjectId,
  }) => _run('removeFromArms', () async {
    final removed = await _supabase
        .from('arm_subjects')
        .delete()
        .eq('subject_id', subjectId)
        .inFilter('arm_id', armIds)
        .select('arm_id');
    refuseIfNothingChanged(removed, leadersOnly);
  }, log: (_) => {'subject_id': subjectId, 'arms': armIds.length});

  /// Gives [toArmId] the subjects [fromArmId] has and it doesn't. Nothing is
  /// removed. Returns how many it added.
  Future<int> copyArmSubjects({
    required String fromArmId,
    required String toArmId,
  }) => _run(
    'copyArmSubjects',
    () async =>
        await _supabase.rpc(
              'copy_arm_subjects',
              params: {'p_from_arm_id': fromArmId, 'p_to_arm_id': toArmId},
            )
            as int,
    log: (added) => {'from': fromArmId, 'to': toArmId, 'added': added},
  );

  /// The subjects [armId] takes, in report-card order, with names. Read
  /// once an arm has been chosen.
  Future<List<SubjectOffering>> listArmOfferings({
    required String organizationId,
    required String armId,
  }) => _run('listArmOfferings', () async {
    final rows = await _supabase
        .from('arm_subjects')
        .select(SubjectOffering.columns)
        .eq('organization_id', organizationId)
        .eq('arm_id', armId);
    return rows.map(SubjectOffering.fromJson).toList()..sort(
      (a, b) => a.sortOrder != b.sortOrder
          ? a.sortOrder.compareTo(b.sortOrder)
          : a.name.compareTo(b.name),
    );
  }, log: (rows) => {'arm_id': armId, 'count': rows.length});

  /// Who teaches what in [armId] for [sessionId]: one row per subject that
  /// has a teacher.
  Future<List<TeachingAssignment>> listArmTeachingAssignments({
    required String organizationId,
    required String sessionId,
    required String armId,
  }) => _run(
    'listArmTeachingAssignments',
    () async {
      final rows = await _supabase
          .from('teaching_assignments')
          .select(TeachingAssignment.columns)
          .eq('organization_id', organizationId)
          .eq('session_id', sessionId)
          .eq('arm_id', armId);
      return rows.map(TeachingAssignment.fromJson).toList();
    },
    log: (rows) => {'arm_id': armId, 'count': rows.length},
  );

  /// One staff member's teaching assignments in the school's current
  /// session. One read: the session is joined inside, so no session id is
  /// needed first.
  Future<List<TeachingAssignment>> getStaffSubjects({
    required String organizationId,
    required String staffId,
  }) => _run('getStaffSubjects', () async {
    final rows = await _supabase
        .from('teaching_assignments')
        .select(TeachingAssignment.currentSessionColumns)
        .eq('organization_id', organizationId)
        .eq('staff_id', staffId)
        .eq('academic_sessions.is_current', true);
    return rows.map(TeachingAssignment.fromJson).toList();
  }, log: (rows) => {'staff_id': staffId, 'count': rows.length});

  /// Gives [subjectId] in [armId] to [staffId]. The arm must take the
  /// subject; the database refuses otherwise.
  Future<void> addTeachingAssignment({
    required String organizationId,
    required String sessionId,
    required String armId,
    required String subjectId,
    required String staffId,
  }) => _run(
    'addTeachingAssignment',
    () async {
      await _supabase.from('teaching_assignments').insert({
        'organization_id': organizationId,
        'session_id': sessionId,
        'arm_id': armId,
        'subject_id': subjectId,
        'staff_id': staffId,
      });
    },
    log: (_) => {'arm_id': armId, 'subject_id': subjectId, 'staff_id': staffId},
    forbidden: assignmentsLeadersOnly,
    duplicate:
        'That subject already has a teacher in this arm. Reload and try '
        'again.',
    invalid:
        "That subject isn't on this arm yet. Add it to the arm's subjects "
        'first.',
  );

  /// Replaces the teacher on an existing assignment.
  Future<void> changeTeachingAssignmentTeacher(
    TeachingAssignment row, {
    required String staffId,
  }) => _run(
    'changeTeachingAssignmentTeacher',
    () async {
      final changed = await _supabase
          .from('teaching_assignments')
          .update({'staff_id': staffId})
          .eq('session_id', row.sessionId)
          .eq('arm_id', row.armId)
          .eq('subject_id', row.subjectId)
          .select('staff_id');
      refuseIfNothingChanged(changed, assignmentsLeadersOnly);
    },
    log: (_) => {'subject_id': row.subjectId, 'staff_id': staffId},
    forbidden: assignmentsLeadersOnly,
  );

  Future<void> _update(String id, Map<String, Object?> values) async {
    if (values.isEmpty) return;
    final changed = await _supabase
        .from('subjects')
        .update(values)
        .eq('id', id)
        .select('id');
    refuseIfNothingChanged(changed, leadersOnly);
  }

  static String _taken(String name, String? code) => code == null
      ? "There's already a subject called $name."
      : "There's already a subject called $name, or with the code $code.";

  Future<T> _run<T>(
    String name,
    Future<T> Function() body, {
    required Map<String, Object?> Function(T result) log,
    String? duplicate,
    String? inUse,
    String? invalid,
    String? forbidden,
  }) => runRefusable(
    name,
    body,
    log: log,
    forbidden: forbidden ?? leadersOnly,
    duplicate: duplicate,
    inUse: inUse,
    invalid: invalid ?? 'Codes are 2 to 10 letters or numbers, with no spaces.',
  );
}
