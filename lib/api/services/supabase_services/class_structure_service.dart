import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sections, classes and arms. School leaders (owner, admins, principal,
/// vice principals) change them; everyone else can only read. The database
/// keeps anything in use: a section with classes, and an arm with students
/// placed in it.
///
/// Refusals come back as [SupabaseRefusal] with a readable message.
/// Row-level security doesn't raise on a blocked update or delete, it just
/// touches no rows, so those calls read back what they changed and treat
/// nothing as a refusal.
class ClassStructureService {
  ClassStructureService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'classes and arms.';

  /// Every section with its classes and arms, in teaching order.
  Future<List<SchoolSection>> getStructure(String organizationId) => _run(
    'getStructure',
    () async {
      final rows = await _supabase
          .from('sections')
          .select(SchoolSection.columns)
          .eq('organization_id', organizationId)
          .order('sort_order')
          .order('name');
      return rows.map(SchoolSection.fromJson).toList();
    },
    log: (sections) => {
      'organization_id': organizationId,
      'sections': sections.length,
    },
  );

  /// Nursery 1–3, Primary 1–6 and JSS 1–SS 3, with SS 3 graduating. Only
  /// for a school with no sections yet. Returns how many classes it made.
  Future<int> createStandardStructure(String organizationId) => _run(
    'createStandardStructure',
    () async =>
        await _supabase.rpc(
              'create_standard_structure',
              params: {'p_organization_id': organizationId},
            )
            as int,
    log: (classes) => {'organization_id': organizationId, 'classes': classes},
  );

  Future<void> addSection({
    required String organizationId,
    required String name,
    required int sortOrder,
  }) => _run(
    'addSection',
    () async {
      await _supabase.from('sections').insert({
        'organization_id': organizationId,
        'name': name,
        'sort_order': sortOrder,
      });
    },
    log: (_) => {'organization_id': organizationId},
    duplicate: "There's already a section called $name.",
  );

  Future<void> updateSection(
    SchoolSection section, {
    String? name,
    bool? isActive,
  }) => _run(
    'updateSection',
    () => _update('sections', section.id, {
      'name': ?name,
      'is_active': ?isActive,
    }),
    log: (_) => {'id': section.id},
    duplicate: "There's already a section called $name.",
  );

  /// Only an empty section can go. Its grading setup goes with it.
  Future<void> deleteSection(SchoolSection section) => _run(
    'deleteSection',
    () => _delete('sections', section.id),
    log: (_) => {'id': section.id},
    inUse:
        '${section.name} still has classes. Remove them first, or switch '
        'the section off.',
  );

  /// Adds a class at the end of its section, with its arms.
  Future<void> addClass({
    required String organizationId,
    required SchoolSection section,
    required String name,
    required bool isGraduating,
    required List<String> arms,
  }) => _run(
    'addClass',
    () async {
      final row = await _supabase
          .from('classes')
          .insert({
            'organization_id': organizationId,
            'section_id': section.id,
            'name': name,
            'sort_order': section.nextClassOrder,
            'is_graduating_class': isGraduating,
          })
          .select('id')
          .single();
      await _insertArms(organizationId, {row['id'] as String: arms});
    },
    log: (_) => {'section_id': section.id, 'arms': arms.length},
    duplicate: "There's already a class called $name.",
  );

  /// Saves the class sheet: name, graduating, and which arms it has.
  ///
  /// Not one transaction. Removed arms go before new ones are added, so an
  /// arm can be removed and added back under the same name. A failure
  /// part-way leaves a valid class; reloading shows what saved.
  Future<void> saveClass(
    SchoolClass original, {
    required String organizationId,
    required String name,
    required bool isGraduating,
    required List<String> arms,
  }) => _run(
    'saveClass',
    () async {
      await _update('classes', original.id, {
        if (name != original.name) 'name': name,
        if (isGraduating != original.isGraduating)
          'is_graduating_class': isGraduating,
      });

      final kept = {for (final arm in arms) arm.toLowerCase()};
      for (final arm in original.arms) {
        if (kept.contains(arm.name.toLowerCase())) continue;
        await _run(
          'saveClass.removeArm',
          () => _delete('class_arms', arm.id),
          log: (_) => {'id': arm.id},
          inUse:
              '${original.armLabel(arm.name)} has students in it, so it '
              "can't be removed. Move them to another arm first.",
        );
      }

      final saved = {for (final arm in original.arms) arm.name.toLowerCase()};
      await _insertArms(organizationId, {
        original.id: [
          for (final arm in arms)
            if (!saved.contains(arm.toLowerCase())) arm,
        ],
      });
    },
    log: (_) => {'id': original.id, 'arms': arms.length},
    duplicate: name == original.name
        ? 'Two arms in a class need different names.'
        : "There's already a class called $name.",
  );

  /// Switched-off classes stay in past records but can't take new students.
  Future<void> setClassActive(SchoolClass schoolClass, bool isActive) => _run(
    'setClassActive',
    () => _update('classes', schoolClass.id, {'is_active': isActive}),
    log: (_) => {'id': schoolClass.id, 'is_active': isActive},
  );

  /// Removes a class and its arms (their class teachers and subjects go
  /// with them). The arms go in one statement, so if students sit in any
  /// of them nothing is removed.
  Future<void> deleteClass(SchoolClass schoolClass) => _run(
    'deleteClass',
    () async {
      if (schoolClass.hasArms) {
        final removed = await _supabase
            .from('class_arms')
            .delete()
            .eq('class_id', schoolClass.id)
            .select('id');
        if (removed.length < schoolClass.arms.length) {
          throw const SupabaseRefusal(leadersOnly);
        }
      }
      await _delete('classes', schoolClass.id);
    },
    log: (_) => {'id': schoolClass.id},
    inUse:
        "${schoolClass.name} has students in its arms, so it can't be "
        'removed. Switch it off instead.',
  );

  /// Gives each of [classes] the same [arms], all in one insert. Returns
  /// how many arms were added.
  Future<int> addArms({
    required String organizationId,
    required List<SchoolClass> classes,
    required List<String> arms,
  }) => _run(
    'addArms',
    () => _insertArms(organizationId, {
      for (final schoolClass in classes) schoolClass.id: arms,
    }),
    log: (added) => {'classes': classes.length, 'arms': added},
    duplicate:
        'Some of these classes already have one of these arms. Pull to '
        'refresh and try again.',
  );

  Future<int> _insertArms(
    String organizationId,
    Map<String, List<String>> armsByClass,
  ) async {
    final rows = [
      for (final MapEntry(key: classId, value: arms) in armsByClass.entries)
        for (final arm in arms)
          {'organization_id': organizationId, 'class_id': classId, 'name': arm},
    ];
    if (rows.isEmpty) return 0;
    await _supabase.from('class_arms').insert(rows);
    return rows.length;
  }

  Future<void> _update(
    String table,
    String id,
    Map<String, Object> values,
  ) async {
    if (values.isEmpty) return;
    final changed = await _supabase
        .from(table)
        .update(values)
        .eq('id', id)
        .select('id');
    refuseIfNothingChanged(changed, leadersOnly);
  }

  Future<void> _delete(String table, String id) async {
    final removed = await _supabase
        .from(table)
        .delete()
        .eq('id', id)
        .select('id');
    refuseIfNothingChanged(removed, leadersOnly);
  }

  Future<T> _run<T>(
    String name,
    Future<T> Function() body, {
    required Map<String, Object?> Function(T result) log,
    String? duplicate,
    String? inUse,
  }) => runRefusable(
    name,
    body,
    log: log,
    forbidden: leadersOnly,
    duplicate: duplicate,
    inUse: inUse,
    invalid: 'Every name needs at least one letter or number.',
  );
}
