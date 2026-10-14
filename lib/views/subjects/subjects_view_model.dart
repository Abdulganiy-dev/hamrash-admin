import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/subjects/curriculum.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// How a school with no subjects yet starts (7.1).
enum SubjectsStart { standard, scratch }

/// The two views on the subjects page (7.2 and 7.6).
enum SubjectsTab { byClass, all }

/// One class on the "By class" view: what its arms take.
class ClassSubjectsSummary {
  const ClassSubjectsSummary({
    required this.details,
    required this.trailing,
    this.needsAttention = false,
  });

  /// "14 compulsory · 3 optional", or each arm's count when they differ.
  final String? details;

  /// "17 subjects", "Varies by arm", "No subjects yet"…
  final String trailing;

  /// Shown in the warning colour: the class can't be taught yet.
  final bool needsAttention;
}

/// 7.1, 7.2, 7.6, 7.7 · Subjects: how to start, what each class takes, and
/// the school's whole list. School leaders change them; bursars look.
///
/// Sheet saves return an error message (null when it worked); confirmed
/// actions throw [AppAlertError] for [AppConfirmSheet]. The message is the
/// database's reason when it refused, see [SupabaseRefusal].
class SubjectsViewModel extends BaseViewModel {
  SubjectsViewModel({
    required this.school,
    SubjectService? subjects,
    ClassStructureService? structure,
  }) : _subjects = subjects ?? locator<SubjectService>(),
       _structure = structure ?? locator<ClassStructureService>();

  final MemberSchool school;
  final SubjectService _subjects;
  final ClassStructureService _structure;

  Curriculum? _curriculum;
  Object? _error;
  bool _changed = false;

  SubjectsTab tab = SubjectsTab.byClass;
  SubjectsStart start = SubjectsStart.standard;
  bool starting = false;
  String? startError;
  String query = '';

  Curriculum get curriculum => _curriculum!;
  Object? get error => _error;
  bool get loading => _curriculum == null && _error == null;
  bool get canChange => school.canRunSetup;

  /// Something was saved, so the page that opened this one should reload.
  bool get changed => _changed;

  bool get hasSubjects => _curriculum?.subjects.isNotEmpty ?? false;

  /// Subjects are given per arm, so a school with neither arms nor subjects
  /// sets up classes first.
  bool get needsArms =>
      _curriculum != null && !curriculum.hasArms && !hasSubjects;

  /// 7.1 · No subjects yet, but arms to give them to.
  bool get showStart => _curriculum != null && !hasSubjects && !needsArms;

  /// Sections with at least one switched-on class.
  List<SchoolSection> get sections => [
    for (final section in curriculum.sections)
      if (section.classes.isNotEmpty) section,
  ];

  /// Subjects whose name or code matches [query].
  List<Subject> get visibleSubjects {
    final wanted = query.trim().toLowerCase();
    if (wanted.isEmpty) return curriculum.subjects;
    return [
      for (final subject in curriculum.subjects)
        if (subject.name.toLowerCase().contains(wanted) ||
            (subject.code?.toLowerCase().contains(wanted) ?? false))
          subject,
    ];
  }

  ClassSubjectsSummary summaryOf(SchoolClass schoolClass) {
    final arms = curriculum.armsOf(schoolClass);
    if (arms.isEmpty) {
      return const ClassSubjectsSummary(
        details: null,
        trailing: 'Add arms first',
      );
    }
    if (!curriculum.sameInAllArms(schoolClass)) {
      return ClassSubjectsSummary(
        details: arms
            .map((arm) => '${arm.name} ${curriculum.subjectsOf(arm.id).length}')
            .join(' · '),
        trailing: 'Varies by arm',
      );
    }
    final subjects = curriculum.subjectsOf(arms.first.id);
    if (subjects.isEmpty) {
      return ClassSubjectsSummary(
        details: arms.length == 1
            ? '1 arm'
            : '${arms.length} arms: ${arms.map((arm) => arm.name).join(', ')}',
        trailing: 'No subjects yet',
        needsAttention: true,
      );
    }
    final compulsory = subjects.values.where((value) => value).length;
    final optional = subjects.length - compulsory;
    return ClassSubjectsSummary(
      details: [
        if (compulsory > 0) '$compulsory compulsory',
        if (optional > 0) '$optional optional',
      ].join(' · '),
      trailing: subjects.length == 1
          ? '1 subject'
          : '${subjects.length} subjects',
    );
  }

  /// "Primary 1 – SS 3 · 12 classes", "Not in any class yet"…
  String usageOf(Subject subject) {
    if (!subject.isActive) return 'Switched off · kept on past report cards';
    final classes = curriculum.classesTaking(subject);
    if (classes.isEmpty) return 'Not in any class yet';
    final span = classes.length == 1
        ? classes.first.name
        : '${classes.first.name} – ${classes.last.name}';
    final count = classes.length == 1 ? null : '${classes.length} classes';
    return [
      span,
      ?count,
      if (curriculum.onlyOptional(subject)) 'optional',
    ].join(' · ');
  }

  /// "Optional in SS 1 – SS 3", for the subject sheet.
  String placeOf(Subject subject) {
    final classes = curriculum.classesTaking(subject);
    if (classes.isEmpty) return 'Not in any class yet';
    final span = classes.length == 1
        ? classes.first.name
        : '${classes.first.name} – ${classes.last.name}';
    return curriculum.onlyOptional(subject) ? 'Optional in $span' : 'In $span';
  }

  /// Why [subject] can't be removed, or null when it can.
  String? removeBlockedReason(Subject subject) {
    if (subject.teachers > 0) {
      return "It's taught, so it can't be removed. Switch it off instead.";
    }
    if (subject.choices > 0) {
      return "Students chose it, so it can't be removed. Switch it off "
          'instead.';
    }
    return null;
  }

  void pickTab(SubjectsTab value) {
    tab = value;
    notifyListeners();
  }

  void pickStart(SubjectsStart value) {
    start = value;
    startError = null;
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Subjects.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Pull to refresh: keeps the page and rethrows for the error toast.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Subjects.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// 7.1 · Creates the 41 common subjects and gives every arm its level's
  /// list. Returns false and sets [startError] when it didn't work.
  Future<bool> useStandardSubjects() async {
    if (starting) return false;
    starting = true;
    startError = null;
    notifyListeners();
    final message = await _save(
      () => _subjects.createStandardSubjects(school.id),
      "Couldn't set up the subjects. Try again.",
      'Subjects.useStandardSubjects',
    );
    starting = false;
    startError = message;
    notifyListeners();
    return message == null;
  }

  /// Adds a subject at the end of the report card. Returns its id, or the
  /// reason it wasn't added.
  Future<({String? id, String? error})> addSubject(
    String name,
    String code,
  ) async {
    String? id;
    final message = await _save(
      () async => id = await _subjects.addSubject(
        organizationId: school.id,
        name: name.trim(),
        code: _code(code),
        sortOrder: curriculum.nextSortOrder,
      ),
      "Couldn't add the subject. Try again.",
      'Subjects.addSubject',
    );
    return (id: id, error: message);
  }

  Future<String?> saveSubject(Subject subject, String name, String code) =>
      _save(
        () => _subjects.updateSubject(
          subject,
          name: name.trim(),
          code: _code(code),
        ),
        "Couldn't save the subject. Try again.",
        'Subjects.saveSubject',
      );

  Future<void> setSubjectActive(Subject subject, bool isActive) => _act(
    () => _subjects.setSubjectActive(subject, isActive),
    "Couldn't change the subject. Try again.",
  );

  Future<void> deleteSubject(Subject subject) => _act(
    () => _subjects.deleteSubject(subject),
    "Couldn't remove the subject. Try again.",
  );

  static String? _code(String code) {
    final value = code.trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  Future<String?> _save(
    Future<void> Function() action,
    String fallback,
    String context,
  ) async {
    try {
      await action();
      _changed = true;
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return messageFor(error, fallback);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback, 'Subjects.action');
    if (message != null) throw AppAlertError(message);
  }

  Future<void> _fetch() async {
    final results = await Future.wait<Object>([
      _structure.getStructure(school.id),
      _subjects.listSubjects(school.id),
      _subjects.listArmSubjects(school.id),
    ]);
    _curriculum = Curriculum(
      sections: results[0] as List<SchoolSection>,
      subjects: results[1] as List<Subject>,
      links: results[2] as List<ArmSubject>,
    );
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
