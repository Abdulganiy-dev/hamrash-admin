import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';

/// The school's structure, subjects, and which arm takes which subject, put
/// together for the subjects pages. Only switched-on sections, classes and
/// arms count: switched-off ones take no new students.
class Curriculum {
  Curriculum({
    required List<SchoolSection> sections,
    required this.subjects,
    required List<ArmSubject> links,
  }) : sections = [
         for (final section in sections)
           if (section.isActive)
             SchoolSection(
               id: section.id,
               name: section.name,
               sortOrder: section.sortOrder,
               isActive: true,
               classes: [
                 for (final schoolClass in section.classes)
                   if (schoolClass.isActive) schoolClass,
               ],
             ),
       ],
       _byArm = _group(links);

  /// Switched-on sections with their switched-on classes, in teaching order.
  final List<SchoolSection> sections;

  /// Every subject, in report-card order.
  final List<Subject> subjects;

  /// arm id → subject id → compulsory.
  final Map<String, Map<String, bool>> _byArm;

  static Map<String, Map<String, bool>> _group(List<ArmSubject> links) {
    final byArm = <String, Map<String, bool>>{};
    for (final link in links) {
      (byArm[link.armId] ??= {})[link.subjectId] = link.isCompulsory;
    }
    return byArm;
  }

  List<SchoolClass> get classes => [
    for (final section in sections) ...section.classes,
  ];

  /// At least one class has an arm to give subjects to.
  bool get hasArms =>
      classes.any((schoolClass) => armsOf(schoolClass).isNotEmpty);

  SchoolClass? classById(String id) {
    for (final schoolClass in classes) {
      if (schoolClass.id == id) return schoolClass;
    }
    return null;
  }

  Subject? subjectById(String id) {
    for (final subject in subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  /// A class's switched-on arms.
  List<ClassArm> armsOf(SchoolClass schoolClass) => [
    for (final arm in schoolClass.arms)
      if (arm.isActive) arm,
  ];

  /// subject id → compulsory, for one arm.
  Map<String, bool> subjectsOf(String armId) => _byArm[armId] ?? const {};

  /// Every arm of the class takes the same subjects, the same way.
  bool sameInAllArms(SchoolClass schoolClass) {
    final arms = armsOf(schoolClass);
    if (arms.length < 2) return true;
    final first = subjectsOf(arms.first.id);
    return arms.skip(1).every((arm) => _sameMap(first, subjectsOf(arm.id)));
  }

  static bool _sameMap(Map<String, bool> a, Map<String, bool> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);

  /// [ids] as subjects, in report-card order.
  List<Subject> inOrder(Iterable<String> ids) {
    final wanted = ids.toSet();
    return [
      for (final subject in subjects)
        if (wanted.contains(subject.id)) subject,
    ];
  }

  /// Classes with an arm that takes [subject], in teaching order.
  List<SchoolClass> classesTaking(Subject subject) => [
    for (final schoolClass in classes)
      if (armsOf(
        schoolClass,
      ).any((arm) => subjectsOf(arm.id).containsKey(subject.id)))
        schoolClass,
  ];

  /// Whether every arm that takes [subject] has it as optional.
  bool onlyOptional(Subject subject) {
    var any = false;
    for (final subjects in _byArm.values) {
      final compulsory = subjects[subject.id];
      if (compulsory == null) continue;
      if (compulsory) return false;
      any = true;
    }
    return any;
  }

  /// Why [name] can't be used for a subject, or null when it can.
  String? subjectNameProblem(String name, {Subject? except}) {
    final wanted = name.trim().toLowerCase();
    for (final subject in subjects) {
      if (subject.id != except?.id && subject.name.toLowerCase() == wanted) {
        return "There's already a subject called ${subject.name}.";
      }
    }
    return null;
  }

  /// Why [code] can't be used, or null when it can (or is left empty).
  String? subjectCodeProblem(String code, {Subject? except}) {
    final wanted = code.trim().toUpperCase();
    if (wanted.isEmpty) return null;
    if (!RegExp(r'^[A-Z0-9]{2,10}$').hasMatch(wanted)) {
      return 'Use 2 to 10 letters or numbers, with no spaces.';
    }
    for (final subject in subjects) {
      if (subject.id != except?.id && subject.code?.toUpperCase() == wanted) {
        return '${subject.name} already uses $wanted.';
      }
    }
    return null;
  }

  /// The next report-card position, for a new subject.
  int get nextSortOrder => subjects.isEmpty ? 1 : subjects.last.sortOrder + 1;
}
