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

/// 7.3–7.5, 7.8 · One class's subjects. When its arms take the same
/// subjects, "All arms" edits them together; otherwise each arm is edited on
/// its own. Bursars look only.
class ClassSubjectsViewModel extends BaseViewModel {
  ClassSubjectsViewModel({
    required this.school,
    required this.classId,
    SubjectService? subjects,
    ClassStructureService? structure,
  }) : _subjects = subjects ?? locator<SubjectService>(),
       _structure = structure ?? locator<ClassStructureService>();

  final MemberSchool school;
  final String classId;
  final SubjectService _subjects;
  final ClassStructureService _structure;

  Curriculum? _curriculum;
  List<ArmSubjectUsage> _usage = const [];
  Object? _error;
  bool _changed = false;
  bool _picked = false;

  /// The arm being edited, or null for all arms together.
  String? armId;

  Curriculum get curriculum => _curriculum!;
  Object? get error => _error;
  bool get loading => _curriculum == null && _error == null;
  bool get canChange => school.canRunSetup;
  bool get changed => _changed;

  /// Null once loaded if the class was removed or switched off meanwhile.
  SchoolClass? get schoolClass => _curriculum?.classById(classId);

  List<ClassArm> get arms =>
      schoolClass == null ? const [] : curriculum.armsOf(schoolClass!);

  bool get sameInAllArms =>
      schoolClass == null || curriculum.sameInAllArms(schoolClass!);

  /// Arm tabs: none for one arm; "All arms" (null) first while they match.
  List<String?> get tabs => arms.length < 2
      ? const []
      : [if (sameInAllArms) null, for (final arm in arms) arm.id];

  String tabLabel(String? id) =>
      id == null ? 'All arms' : arms.firstWhere((arm) => arm.id == id).name;

  ClassArm? get arm {
    for (final each in arms) {
      if (each.id == armId) return each;
    }
    return null;
  }

  /// The arms a change applies to.
  List<String> get targetArmIds =>
      armId == null ? [for (final each in arms) each.id] : [armId!];

  /// subject id → compulsory, for what's on screen.
  Map<String, bool> get _shown =>
      arms.isEmpty ? const {} : curriculum.subjectsOf(armId ?? arms.first.id);

  List<Subject> get compulsory => curriculum.inOrder(
    _shown.entries.where((entry) => entry.value).map((entry) => entry.key),
  );

  List<Subject> get optional => curriculum.inOrder(
    _shown.entries.where((entry) => !entry.value).map((entry) => entry.key),
  );

  bool isCompulsory(Subject subject) => _shown[subject.id] ?? false;

  /// Switched-on subjects not on screen yet, for the add sheet.
  List<Subject> get addable => [
    for (final subject in curriculum.subjects)
      if (subject.isActive && !_shown.containsKey(subject.id)) subject,
  ];

  /// "JSS 1A, JSS 1B and JSS 1C", or "JSS 1 Science".
  String get targetLabel {
    final c = schoolClass;
    if (c == null) return '';
    final labels = [
      for (final each in arms)
        if (targetArmIds.contains(each.id)) c.armLabel(each.name),
    ];
    return _list(labels);
  }

  /// The line under the arm tabs, or null for a one-arm class.
  String? get note {
    final c = schoolClass;
    if (c == null || arms.length < 2) return null;
    if (armId == null) {
      final all = switch (arms.length) {
        2 => 'both',
        3 => 'all three',
        _ => 'all ${arms.length}',
      };
      return '$targetLabel take the same subjects. Changes here apply to '
          '$all.';
    }
    return sameInAllArms
        ? 'Changes here apply to $targetLabel only.'
        : "${c.name}'s arms take different subjects. Changes here apply to "
              '$targetLabel only.';
  }

  /// Why [subject] can't come off the arms being edited, or null when it
  /// can: a teacher is assigned to it there this session, or students
  /// there chose it.
  String? removeBlockedReason(Subject subject) {
    final c = schoolClass;
    if (c == null) return null;
    final labels = {for (final each in arms) each.id: c.armLabel(each.name)};
    final inUse = [
      for (final usage in _usage)
        if (usage.subjectId == subject.id && targetArmIds.contains(usage.armId))
          usage,
    ];
    for (final usage in inUse) {
      if (usage.teacherName case final teacher?) {
        return '$teacher teaches ${subject.name} in ${labels[usage.armId]}. '
            'Unassign them first.';
      }
    }
    for (final usage in inUse) {
      if (usage.choices > 0) {
        final students = usage.choices == 1
            ? '1 student'
            : '${usage.choices} students';
        return '$students in ${labels[usage.armId]} chose ${subject.name}. '
            'Remove their choice first.';
      }
    }
    return null;
  }

  /// Other arms [arm]'s subjects can be copied to.
  List<ClassArm> get copyTargets => [
    for (final each in arms)
      if (each.id != armId) each,
  ];

  void pickArm(String? id) {
    armId = id;
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
        context: 'ClassSubjects.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ClassSubjects.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// 7.5 · Returns the reason when it didn't work.
  Future<String?> addSubjects(
    List<String> subjectIds, {
    required bool compulsory,
  }) => _save(
    () => _subjects.addToArms(
      organizationId: school.id,
      armIds: targetArmIds,
      subjectIds: subjectIds,
      isCompulsory: compulsory,
    ),
    "Couldn't add the subjects. Try again.",
  );

  /// 7.4 · Returns the reason when it didn't work.
  Future<String?> setCompulsory(Subject subject, bool compulsory) => _save(
    () => _subjects.setCompulsory(
      armIds: targetArmIds,
      subjectId: subject.id,
      isCompulsory: compulsory,
    ),
    "Couldn't change ${subject.name}. Try again.",
  );

  /// 7.4 · For [AppConfirmSheet.onConfirm].
  Future<void> removeSubject(Subject subject) => _act(
    () => _subjects.removeFromArms(armIds: targetArmIds, subjectId: subject.id),
    "Couldn't remove ${subject.name}. Try again.",
  );

  /// 7.8 · Gives [to] the subjects the current arm has and it doesn't.
  Future<void> copyTo(ClassArm to) => _act(
    () => _subjects.copyArmSubjects(fromArmId: armId!, toArmId: to.id),
    "Couldn't copy the subjects. Try again.",
  );

  /// "Not listed? Create a subject" from the add sheet. Returns its id, or
  /// the reason it wasn't added.
  Future<({String? id, String? error})> createSubject(
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
    );
    return (id: id, error: message);
  }

  /// "Edit name or code" from a subject's actions.
  Future<({String? id, String? error})> saveSubject(
    Subject subject,
    String name,
    String code,
  ) async {
    final message = await _save(
      () => _subjects.updateSubject(
        subject,
        name: name.trim(),
        code: _code(code),
      ),
      "Couldn't save the subject. Try again.",
    );
    return (id: message == null ? subject.id : null, error: message);
  }

  static String? _code(String code) {
    final value = code.trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  Future<String?> _save(Future<void> Function() action, String fallback) async {
    try {
      await action();
      _changed = true;
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ClassSubjects.save',
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return error is SupabaseRefusal ? error.message : fallback;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback);
    if (message != null) throw AppAlertError(message);
  }

  Future<void> _fetch() async {
    final results = await Future.wait<Object?>([
      _structure.getStructure(school.id),
      _subjects.listSubjects(school.id),
      _subjects.listArmSubjects(school.id),
      // The page still works without it; the database refuses anyway.
      _optional(_subjects.listArmSubjectUsage(school.id)),
    ]);
    _curriculum = Curriculum(
      sections: results[0]! as List<SchoolSection>,
      subjects: results[1]! as List<Subject>,
      links: results[2]! as List<ArmSubject>,
    );
    _usage = results[3] as List<ArmSubjectUsage>? ?? const [];
    _keepArmValid();
  }

  static Future<T?> _optional<T>(Future<T> request) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  /// Starts on "All arms" when the arms match, else on the first arm; and
  /// keeps the pick valid as arms come and go.
  void _keepArmValid() {
    final ids = [for (final each in arms) each.id];
    if (!_picked) {
      _picked = true;
      armId = sameInAllArms || ids.isEmpty ? null : ids.first;
      return;
    }
    if (armId != null && !ids.contains(armId)) armId = null;
    if (armId == null && !sameInAllArms && ids.isNotEmpty) armId = ids.first;
  }

  static String _list(List<String> items) => switch (items.length) {
    0 => '',
    1 => items.first,
    _ => '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}',
  };
}
