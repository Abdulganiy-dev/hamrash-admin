import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';

/// What the Students and Staff filter sheets offer to pick from: the
/// school's classes (each with its arms) and its subjects.
class PeopleFilterOptions {
  const PeopleFilterOptions({
    required this.classes,
    required this.armsOf,
    required this.subjects,
  });

  static const empty = PeopleFilterOptions(
    classes: [],
    armsOf: {},
    subjects: [],
  );

  /// In teaching order.
  final List<FilterPick> classes;

  /// The arms of each class, by class id.
  final Map<String, List<FilterPick>> armsOf;

  /// A to Z.
  final List<FilterPick> subjects;

  List<FilterPick> armsIn(FilterPick? schoolClass) =>
      schoolClass == null ? const [] : (armsOf[schoolClass.id] ?? const []);
}

/// Reads the options once and keeps them while the People tab is open.
class PeopleFilterOptionsLoader {
  PeopleFilterOptionsLoader({
    required this.organizationId,
    ClassStructureService? structure,
    SubjectService? subjects,
  }) : _structureOverride = structure,
       _subjectsOverride = subjects;

  final String organizationId;

  // Resolved when first read, so building the tab costs nothing.
  final ClassStructureService? _structureOverride;
  final SubjectService? _subjectsOverride;

  Future<PeopleFilterOptions>? _pending;

  /// Loads on the first call. A failure isn't kept, so the next open of a
  /// sheet tries again.
  Future<PeopleFilterOptions> load() =>
      _pending ??= _read().catchError((Object error) {
        _pending = null;
        throw error;
      });

  Future<PeopleFilterOptions> _read() async {
    final results = await Future.wait<Object>([
      (_structureOverride ?? locator<ClassStructureService>()).getStructure(
        organizationId,
      ),
      (_subjectsOverride ?? locator<SubjectService>()).listSubjects(
        organizationId,
      ),
    ]);
    final sections = results[0] as List<SchoolSection>;
    final subjects = results[1] as List<Subject>;
    final classes = <FilterPick>[];
    final armsOf = <String, List<FilterPick>>{};
    for (final section in sections) {
      for (final schoolClass in section.classes) {
        if (!schoolClass.isActive) continue;
        final pick = FilterPick(schoolClass.id, schoolClass.name);
        classes.add(pick);
        armsOf[pick.id] = [
          for (final arm in schoolClass.arms)
            if (arm.isActive) FilterPick(arm.id, arm.name),
        ];
      }
    }
    final picks = [
      for (final subject in subjects)
        if (subject.isActive) FilterPick(subject.id, subject.name),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return PeopleFilterOptions(classes: classes, armsOf: armsOf, subjects: picks);
  }
}
