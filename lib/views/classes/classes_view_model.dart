import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// How a school with no classes yet starts (6.1).
enum StructureStart { standard, scratch }

/// 6.1–6.4 · Classes and arms. School leaders set up and change the
/// structure; bursars can look at it.
///
/// Sheet saves return an error message (null when it worked) so the sheet
/// stays open and shows it. Confirmed actions throw [AppAlertError] for
/// [AppConfirmSheet]. Either way the message is the database's reason when
/// it refused, see [ClassStructureService].
class ClassesViewModel extends BaseViewModel {
  ClassesViewModel({required this.school, ClassStructureService? service})
    : _service = service ?? locator<ClassStructureService>();

  final MemberSchool school;
  final ClassStructureService _service;

  List<SchoolSection>? _sections;
  Object? _error;
  bool _changed = false;

  StructureStart start = StructureStart.standard;
  bool starting = false;
  String? startError;

  List<SchoolSection> get sections => _sections ?? const [];
  Object? get error => _error;
  bool get loading => _sections == null && _error == null;
  bool get isEmpty => _sections?.isEmpty ?? false;

  bool get canChange => school.canRunSetup;

  /// Something was saved, so the page that opened this one should reload.
  bool get changed => _changed;

  /// Classes in use that still need an arm before pupils can be placed.
  List<SchoolClass> get classesWithoutArms => [
    for (final (_, classes) in sectionsNeedingArms) ...classes,
  ];

  /// Each switched-on section with its switched-on classes that have no
  /// arms, for the "Add arms" sheet (6.4).
  List<(SchoolSection, List<SchoolClass>)> get sectionsNeedingArms => [
    for (final section in sections)
      if (section.isActive)
        if ([
              for (final schoolClass in section.classes)
                if (schoolClass.isActive && !schoolClass.hasArms) schoolClass,
            ]
            case final classes when classes.isNotEmpty)
          (section, classes),
  ];

  /// Sections that can take a new class.
  List<SchoolSection> get activeSections => [
    for (final section in sections)
      if (section.isActive) section,
  ];

  /// "Primary · comes after Nursery 3", or "Nursery · the first class".
  String placeOf(SchoolClass schoolClass) {
    final section = _sectionOf(schoolClass);
    SchoolClass? previous;
    for (final each in sections.expand((section) => section.classes)) {
      if (each.id == schoolClass.id) break;
      previous = each;
    }
    return previous == null
        ? '${section.name} · the first class'
        : '${section.name} · comes after ${previous.name}';
  }

  /// "Primary · after Primary 6" for a class about to be added.
  String placeOfNew(SchoolSection section) => section.classes.isEmpty
      ? '${section.name} · its first class'
      : '${section.name} · after ${section.classes.last.name}';

  /// Why [name] can't be used for a class, or null when it can.
  String? classNameProblem(String name, {SchoolClass? except}) {
    final wanted = name.trim().toLowerCase();
    for (final each in sections.expand((section) => section.classes)) {
      if (each.id != except?.id && each.name.toLowerCase() == wanted) {
        return "There's already a class called ${each.name}.";
      }
    }
    return null;
  }

  /// Why [name] can't be used for a section, or null when it can.
  String? sectionNameProblem(String name, {SchoolSection? except}) {
    final wanted = name.trim().toLowerCase();
    for (final each in sections) {
      if (each.id != except?.id && each.name.toLowerCase() == wanted) {
        return "There's already a section called ${each.name}.";
      }
    }
    return null;
  }

  /// Why [schoolClass] can't be removed, or null when it can: an arm has
  /// students placed in it or a class teacher.
  String? removeClassBlockedReason(SchoolClass schoolClass) {
    final arm = schoolClass.busyArm;
    if (arm == null) return null;
    final label = schoolClass.armLabel(arm.name);
    final why = arm.students > 0
        ? 'Students are placed in $label'
        : '$label has a class teacher';
    return "$why, so ${schoolClass.name} can't be removed. Switch it off "
        'instead.';
  }

  /// Why [section] can't be removed, or null when it can.
  String? removeSectionBlockedReason(SchoolSection section) =>
      section.classes.isEmpty
      ? null
      : 'Remove its classes first, or switch the section off.';

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
        context: 'Classes.load',
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
        context: 'Classes.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void pickStart(StructureStart value) {
    start = value;
    startError = null;
    notifyListeners();
  }

  /// 6.1 · Creates Nursery 1 to SS 3. Returns false and sets [startError]
  /// when it didn't work.
  Future<bool> useStandardStructure() async {
    if (starting) return false;
    starting = true;
    startError = null;
    notifyListeners();
    final message = await _save(
      () => _service.createStandardStructure(school.id),
      "Couldn't set up the classes. Try again.",
      'Classes.useStandardStructure',
    );
    starting = false;
    startError = message;
    notifyListeners();
    return message == null;
  }

  Future<String?> addSection(String name) => _save(
    () => _service.addSection(
      organizationId: school.id,
      name: name.trim(),
      sortOrder: sections.isEmpty ? 1 : sections.last.sortOrder + 1,
    ),
    "Couldn't add the section. Try again.",
    'Classes.addSection',
  );

  Future<String?> renameSection(SchoolSection section, String name) => _save(
    () => _service.updateSection(section, name: name.trim()),
    "Couldn't save the section. Try again.",
    'Classes.renameSection',
  );

  Future<void> setSectionActive(SchoolSection section, bool isActive) => _act(
    () => _service.updateSection(section, isActive: isActive),
    "Couldn't change the section. Try again.",
  );

  Future<void> deleteSection(SchoolSection section) => _act(
    () => _service.deleteSection(section),
    "Couldn't remove the section. Try again.",
  );

  Future<String?> addClass(
    SchoolSection section, {
    required String name,
    required bool isGraduating,
    required List<String> arms,
  }) => _save(
    () => _service.addClass(
      organizationId: school.id,
      section: section,
      name: name.trim(),
      isGraduating: isGraduating,
      arms: arms,
    ),
    "Couldn't add the class. Try again.",
    'Classes.addClass',
  );

  Future<String?> saveClass(
    SchoolClass schoolClass, {
    required String name,
    required bool isGraduating,
    required List<String> arms,
  }) => _save(
    () => _service.saveClass(
      schoolClass,
      organizationId: school.id,
      name: name.trim(),
      isGraduating: isGraduating,
      arms: arms,
    ),
    "Couldn't save the class. Try again.",
    'Classes.saveClass',
  );

  Future<void> setClassActive(SchoolClass schoolClass, bool isActive) => _act(
    () => _service.setClassActive(schoolClass, isActive),
    "Couldn't change the class. Try again.",
  );

  Future<void> deleteClass(SchoolClass schoolClass) => _act(
    () => _service.deleteClass(schoolClass),
    "Couldn't remove the class. Try again.",
  );

  /// 6.4 · Gives [arms] to every class in [sectionIds] that has none yet.
  Future<String?> addArms(List<String> arms, Set<String> sectionIds) => _save(
    () => _service.addArms(
      organizationId: school.id,
      classes: [
        for (final (section, classes) in sectionsNeedingArms)
          if (sectionIds.contains(section.id)) ...classes,
      ],
      arms: arms,
    ),
    "Couldn't add the arms. Try again.",
    'Classes.addArms',
  );

  /// Runs a save and reloads. Returns the message to show, or null.
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
      // Some steps may have saved; show what the database now holds.
      await _fetch().catchError((_) {});
      return messageFor(error, fallback);
    } finally {
      notifyListeners();
    }
  }

  /// For [AppConfirmSheet.onConfirm]: throws [AppAlertError] to keep the
  /// sheet open with the reason.
  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback, 'Classes.action');
    if (message != null) throw AppAlertError(message);
  }

  Future<void> _fetch() async {
    _sections = await _service.getStructure(school.id);
  }

  SchoolSection _sectionOf(SchoolClass schoolClass) =>
      sections.firstWhere((section) => section.id == schoolClass.sectionId);

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
