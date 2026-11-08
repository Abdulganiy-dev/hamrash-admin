import 'dart:async';

import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_catalog.dart';

/// Which change a teaching sheet saved, so the staff page can say so.
enum TeachingChange { homeroom, subject }

/// The colour a sheet's note block takes. The sheet maps it to the tokens.
enum TeachingTone { neutral, success, warning, error }

/// What the Set homeroom sheet says and offers for the current choice.
class HomeroomSave {
  const HomeroomSave({
    required this.note,
    required this.tone,
    required this.buttonLabel,
    required this.canSave,
    this.readOnly = false,
  });

  final String note;
  final TeachingTone tone;
  final String buttonLabel;
  final bool canSave;

  /// A closed session: the pickers and the lead/assistant toggle are off.
  final bool readOnly;
}

/// What the Set subject sheet says and offers for the current choice.
class SubjectSave {
  const SubjectSave({
    required this.note,
    required this.tone,
    required this.buttonLabel,
    required this.canSave,
    this.readOnly = false,
    this.addSubjects = false,
  });

  final String note;
  final TeachingTone tone;
  final String buttonLabel;
  final bool canSave;

  /// A closed session: everything is read-only.
  final bool readOnly;

  /// The arm has no curriculum, so the sheet offers a way to add one.
  final bool addSubjects;
}

/// The teaching setup behind one staff member, read a step at a time:
///
///  * the menu needs the current session ([loadSession]),
///  * either sheet then needs the classes and arms ([loadStructure]), shared
///    through the page's [TeachingCatalog],
///  * the homeroom sheet reads who looks after an arm only once that arm is
///    chosen ([loadRoster]),
///  * the subject sheet reads what the arm takes and who teaches it only once
///    that arm is chosen ([loadArmSubjects]).
///
/// Each note and button is worked out from the arm's own reads, in the
/// session that was read, so a warning always names the right class, arm and
/// subject.
///
/// Writes return the reason they failed (null when saved), the database's
/// message when it refused, see [SupabaseRefusal].
class TeachingSetupViewModel extends BaseViewModel {
  TeachingSetupViewModel({
    required this.school,
    required this.staff,
    required this.catalog,
    this.homerooms = const [],
    this.assignments = const [],
    ClassStructureService? structure,
    SubjectService? subjects,
  }) : _structure = structure ?? locator<ClassStructureService>(),
       _subjects = subjects ?? locator<SubjectService>();

  final MemberSchool school;
  final StaffMember staff;
  final TeachingCatalog catalog;

  /// This person's homeroom rows and subjects this session, already read by
  /// the staff page; they only feed the menu's captions.
  final List<ClassTeacher> homerooms;
  final List<TeachingAssignment> assignments;

  final ClassStructureService _structure;
  final SubjectService _subjects;

  AcademicSession? _session;
  bool _sessionLoaded = false;
  Object? _sessionError;

  List<SchoolSection> _sections = const [];
  bool _structureLoaded = false;
  Object? _structureError;

  final _rosters = <String, List<ClassTeacher>>{};
  final _rostersLoading = <String>{};
  final _rostersFailed = <String>{};

  final _offerings = <String, List<SubjectOffering>>{};
  final _armAssignments = <String, List<TeachingAssignment>>{};
  final _armsLoading = <String>{};
  final _armsFailed = <String>{};

  bool _changed = false;

  AcademicSession? get session => _session;
  Object? get error => _sessionError;
  bool get loading => !_sessionLoaded && _sessionError == null;

  /// Something was saved, so the staff page should reload.
  bool get changed => _changed;

  bool get hasSession => _session != null;

  /// A closed session is read-only; the database refuses every write.
  bool get closed => _session?.isClosed ?? false;

  /// "2026/27".
  String get schoolYear => _session?.name ?? '';

  /// "Ngozi Eze".
  String get staffName => staff.fullName;

  bool get structureLoading => !_structureLoaded && _structureError == null;
  Object? get structureError => _structureError;

  /// Switched-on classes with at least one switched-on arm, in teaching
  /// order. The pickers only offer what can take a teacher now.
  List<SchoolClass> get classes => [
    for (final section in _sections)
      if (section.isActive)
        for (final schoolClass in section.classes)
          if (schoolClass.isActive && armsOf(schoolClass).isNotEmpty)
            schoolClass,
  ];

  List<ClassArm> armsOf(SchoolClass schoolClass) => [
    for (final arm in schoolClass.arms)
      if (arm.isActive) arm,
  ];

  /// The class [armId] belongs to, or null when it is gone.
  SchoolClass? classForArm(String armId) {
    for (final section in _sections) {
      for (final schoolClass in section.classes) {
        for (final arm in schoolClass.arms) {
          if (arm.id == armId) return schoolClass;
        }
      }
    }
    return null;
  }

  /// The arm with [armId], or null when it is gone.
  ClassArm? armById(String? armId) {
    if (armId == null) return null;
    for (final section in _sections) {
      for (final schoolClass in section.classes) {
        for (final arm in schoolClass.arms) {
          if (arm.id == armId) return arm;
        }
      }
    }
    return null;
  }

  /// "JSS 1 Gold" for [armId], or an empty string when it is missing.
  String armLabel(String armId) {
    final schoolClass = classForArm(armId);
    final arm = armById(armId);
    if (schoolClass == null || arm == null) return '';
    return fullArmName(schoolClass.name, arm.name);
  }

  /// The staff member's homeroom row this session, lead first.
  ClassTeacher? get homeroom {
    for (final row in homerooms) {
      if (row.isLead) return row;
    }
    return homerooms.isEmpty ? null : homerooms.first;
  }

  /// "{Class}{Arm} · Lead teacher", or "Not set".
  String get homeroomCaption {
    final row = homeroom;
    if (row == null) return 'Not set';
    final role = row.isLead ? 'Lead teacher' : 'Assistant teacher';
    return '${row.armLabel} · $role';
  }

  /// How many subjects the staff member teaches this session.
  int get subjectCount => assignments.length;

  /// "3 subjects this session", or "None this session".
  String get subjectCaption {
    if (subjectCount == 0) return 'None this session';
    final noun = subjectCount == 1 ? 'subject' : 'subjects';
    return '$subjectCount $noun this session';
  }

  // ── Homeroom: one arm's roster ──────────────────────────────────────────

  /// Whether who looks after [armId] has been read.
  bool rosterReady(String armId) => _rosters.containsKey(armId);
  bool rosterLoading(String armId) => _rostersLoading.contains(armId);
  bool rosterFailed(String armId) => _rostersFailed.contains(armId);

  /// The lead of [armId], or null when nobody leads it yet.
  ClassTeacher? leadOf(String armId) {
    for (final row in _rosters[armId] ?? const <ClassTeacher>[]) {
      if (row.isLead) return row;
    }
    return null;
  }

  /// The assistants of [armId] this session.
  List<ClassTeacher> assistantsOf(String armId) => [
    for (final row in _rosters[armId] ?? const <ClassTeacher>[])
      if (!row.isLead) row,
  ];

  /// The class teacher row for [staffId] on [armId], if any.
  ClassTeacher? classTeacherFor(String armId, String staffId) {
    for (final row in _rosters[armId] ?? const <ClassTeacher>[]) {
      if (row.staffId == staffId) return row;
    }
    return null;
  }

  // ── Subject: one arm's curriculum and teachers ──────────────────────────

  bool armSubjectsReady(String armId) =>
      _offerings.containsKey(armId) && _armAssignments.containsKey(armId);
  bool armSubjectsLoading(String armId) => _armsLoading.contains(armId);
  bool armSubjectsFailed(String armId) => _armsFailed.contains(armId);

  /// The subjects [armId] takes, in report-card order.
  List<SubjectOffering> subjectsOn(String armId) =>
      _offerings[armId] ?? const [];

  /// "Compulsory" or "Choice", for the subject picker's caption.
  String subjectCaptionFor(SubjectOffering offering) =>
      offering.isCompulsory ? 'Compulsory' : 'Choice';

  SubjectOffering? offeringById(String armId, String? subjectId) {
    if (subjectId == null) return null;
    for (final offering in subjectsOn(armId)) {
      if (offering.subjectId == subjectId) return offering;
    }
    return null;
  }

  /// The teacher set for [subjectId] in [armId] this session, if anyone.
  TeachingAssignment? assignmentFor(String armId, String subjectId) {
    for (final row in _armAssignments[armId] ?? const <TeachingAssignment>[]) {
      if (row.subjectId == subjectId) return row;
    }
    return null;
  }

  /// The note and button the Set homeroom sheet shows for [armId] and the
  /// chosen role, worked out from what was loaded.
  HomeroomSave homeroomSave({required String? armId, required bool isLead}) {
    if (closed) {
      return const HomeroomSave(
        note: 'This session is closed. Reopen it to change who teaches where.',
        tone: TeachingTone.error,
        buttonLabel: 'Save homeroom',
        canSave: false,
        readOnly: true,
      );
    }
    if (armId == null) {
      return const HomeroomSave(
        note: 'Choose a class and arm to set a homeroom.',
        tone: TeachingTone.neutral,
        buttonLabel: 'Save homeroom',
        canSave: false,
      );
    }
    final label = armLabel(armId);
    if (!rosterReady(armId)) {
      final failed = rosterFailed(armId);
      return HomeroomSave(
        note: failed
            ? "Couldn't check who looks after $label. Choose the arm again "
                  'to retry.'
            : 'Checking who looks after $label…',
        tone: failed ? TeachingTone.error : TeachingTone.neutral,
        buttonLabel: 'Save homeroom',
        canSave: false,
      );
    }
    final existing = classTeacherFor(armId, staff.id);
    final role = isLead ? 'lead' : 'assistant';

    if (existing != null && existing.isLead == isLead) {
      return HomeroomSave(
        note:
            '$staffName is already the $role of $label. '
            'Nothing to change here.',
        tone: TeachingTone.success,
        buttonLabel: isLead ? 'Already the lead' : 'Already an assistant',
        canSave: false,
      );
    }

    if (!isLead) {
      final others = [
        for (final assistant in assistantsOf(armId))
          if (assistant.staffId != staff.id) assistant,
      ];
      if (others.length >= 2) {
        return HomeroomSave(
          note:
              '$label already has 2 assistants: '
              '${_and([for (final other in others) other.staffName])}. '
              'Save as lead, or free a slot first.',
          tone: TeachingTone.error,
          buttonLabel: 'Save homeroom',
          canSave: false,
        );
      }
    }

    if (existing != null) {
      final current = existing.isLead ? 'lead' : 'assistant';
      final displaced = isLead && !existing.isLead ? leadOf(armId) : null;
      if (displaced != null && displaced.staffId != staff.id) {
        return HomeroomSave(
          note:
              '$staffName is an assistant of $label. Saving makes them the '
              'lead and moves ${displaced.staffName} to assistant.',
          tone: TeachingTone.warning,
          buttonLabel: 'Switch to lead',
          canSave: true,
        );
      }
      return HomeroomSave(
        note:
            '$staffName is the $current of $label. Saving moves them to '
            "$role in the same slot — one person can't be both.",
        tone: TeachingTone.neutral,
        buttonLabel: isLead ? 'Switch to lead' : 'Switch to assistant',
        canSave: true,
      );
    }

    final lead = leadOf(armId);
    if (lead != null && isLead) {
      return HomeroomSave(
        note:
            '${lead.staffName} is the lead of $label. Saving makes them an '
            'assistant.',
        tone: TeachingTone.warning,
        buttonLabel: 'Save homeroom',
        canSave: true,
      );
    }
    if (lead != null) {
      return HomeroomSave(
        note:
            'Saving makes $staffName an assistant of $label. '
            '${lead.staffName} stays the lead.',
        tone: TeachingTone.neutral,
        buttonLabel: 'Save homeroom',
        canSave: true,
      );
    }
    return HomeroomSave(
      note: 'Nothing has been set for $label yet.',
      tone: TeachingTone.neutral,
      buttonLabel: 'Save homeroom',
      canSave: true,
    );
  }

  /// The note and button the Set subject sheet shows for the chosen arm and
  /// subject, worked out from what was loaded.
  SubjectSave subjectSave({
    required String? armId,
    required String? subjectId,
  }) {
    if (closed) {
      return const SubjectSave(
        note: 'This session is closed. Reopen it to change who teaches where.',
        tone: TeachingTone.error,
        buttonLabel: 'Save subject',
        canSave: false,
        readOnly: true,
      );
    }
    if (armId == null) {
      return const SubjectSave(
        note: 'Choose a class and arm first.',
        tone: TeachingTone.neutral,
        buttonLabel: 'Save subject',
        canSave: false,
      );
    }
    final label = armLabel(armId);
    if (!armSubjectsReady(armId)) {
      final failed = armSubjectsFailed(armId);
      return SubjectSave(
        note: failed
            ? "Couldn't load the subjects for $label. Choose the arm again "
                  'to retry.'
            : 'Checking the subjects and teachers for $label…',
        tone: failed ? TeachingTone.error : TeachingTone.neutral,
        buttonLabel: 'Save subject',
        canSave: false,
      );
    }
    if (subjectsOn(armId).isEmpty) {
      return SubjectSave(
        note:
            '$label has no subjects on its curriculum yet. A subject has to '
            'be on the arm before a teacher can be set for it.',
        tone: TeachingTone.neutral,
        buttonLabel: 'Save subject',
        canSave: false,
        addSubjects: true,
      );
    }
    if (subjectId == null) {
      return SubjectSave(
        note: 'Choose a subject for $label.',
        tone: TeachingTone.neutral,
        buttonLabel: 'Save subject',
        canSave: false,
      );
    }
    final name = offeringById(armId, subjectId)?.name ?? '';
    final existing = assignmentFor(armId, subjectId);
    if (existing?.staffId == staff.id) {
      return SubjectSave(
        note:
            '$staffName already teaches $name in $label. '
            'Nothing to change here.',
        tone: TeachingTone.success,
        buttonLabel: 'Already taught',
        canSave: false,
      );
    }
    if (existing != null) {
      return SubjectSave(
        note:
            '${existing.staffName} teaches $name in $label. Saving replaces '
            'them.',
        tone: TeachingTone.neutral,
        buttonLabel: 'Save subject',
        canSave: true,
      );
    }
    return SubjectSave(
      note: '$label has no teacher for $name yet.',
      tone: TeachingTone.neutral,
      buttonLabel: 'Save subject',
      canSave: true,
    );
  }

  Future<void> loadSession() async {
    _sessionError = null;
    notifyListeners();
    try {
      _session = await catalog.session();
      _sessionLoaded = true;
    } catch (error, stackTrace) {
      _sessionError = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.loadSession',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Classes and arms, from the page's cache when it already has them.
  Future<void> loadStructure() async {
    if (_structureLoaded) return;
    // Only a retry has anything to redraw; a first call comes from initState.
    if (_structureError != null) {
      _structureError = null;
      notifyListeners();
    }
    try {
      _sections = await catalog.sections();
      _structureLoaded = true;
    } catch (error, stackTrace) {
      _structureError = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.loadStructure',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Reads who looks after [armId] this session. Called when the arm is
  /// chosen; an arm already read in this sheet is not read again.
  Future<void> loadRoster(String armId) async {
    final session = _session;
    if (session == null) return;
    if (_rosters.containsKey(armId) || _rostersLoading.contains(armId)) return;
    _rostersFailed.remove(armId);
    _rostersLoading.add(armId);
    notifyListeners();
    try {
      _rosters[armId] = await _structure.listArmClassTeachers(
        organizationId: school.id,
        sessionId: session.id,
        armId: armId,
      );
    } catch (error, stackTrace) {
      _rostersFailed.add(armId);
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.loadRoster',
        showErrorModal: false,
      );
    }
    _rostersLoading.remove(armId);
    notifyListeners();
  }

  /// Reads what [armId] takes and who teaches each subject there this
  /// session. Called when the arm is chosen; the two reads run together.
  Future<void> loadArmSubjects(String armId) async {
    final session = _session;
    if (session == null) return;
    if (armSubjectsReady(armId) || _armsLoading.contains(armId)) return;
    _armsFailed.remove(armId);
    _armsLoading.add(armId);
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _subjects.listArmOfferings(organizationId: school.id, armId: armId),
        _subjects.listArmTeachingAssignments(
          organizationId: school.id,
          sessionId: session.id,
          armId: armId,
        ),
      ]);
      _offerings[armId] = results[0] as List<SubjectOffering>;
      _armAssignments[armId] = results[1] as List<TeachingAssignment>;
    } catch (error, stackTrace) {
      _armsFailed.add(armId);
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.loadArmSubjects',
        showErrorModal: false,
      );
    }
    _armsLoading.remove(armId);
    notifyListeners();
  }

  /// Forgets what was read about arms' subjects, e.g. after subjects were
  /// added to one, so the next choice reads it again.
  void forgetArmSubjects() {
    _offerings.clear();
    _armAssignments.clear();
    _armsFailed.clear();
    notifyListeners();
  }

  /// Makes this person the lead or an assistant of [armId]. Updates the row
  /// when the arm's roster already has them, otherwise inserts one. Returns
  /// the reason it failed, or null when it saved.
  Future<String?> saveHomeroom({
    required String armId,
    required bool isLead,
  }) async {
    final session = _session;
    if (session == null) return "There's no current session to save into.";
    if (closed) return _closedNote;
    if (!rosterReady(armId)) return 'Still checking who looks after this arm.';
    try {
      final existing = classTeacherFor(armId, staff.id);
      if (existing != null) {
        if (existing.isLead != isLead) {
          await _structure.updateClassTeacherRole(existing, isLead: isLead);
          _changed = true;
        }
      } else {
        await _structure.addClassTeacher(
          organizationId: school.id,
          sessionId: session.id,
          armId: armId,
          staffId: staff.id,
          isLead: isLead,
        );
        _changed = true;
      }
      _rosters.remove(armId);
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.saveHomeroom',
        showErrorModal: false,
      );
      // The roster may have moved under us; read it again for the next try.
      _rosters.remove(armId);
      unawaited(loadRoster(armId));
      return messageFor(error, "Couldn't set the homeroom. Try again.");
    } finally {
      notifyListeners();
    }
  }

  /// Gives [subjectId] in [armId] to this staff member, replacing whoever
  /// had it. Returns the reason it failed, or null when it saved.
  Future<String?> saveSubject({
    required String armId,
    required String subjectId,
  }) async {
    final session = _session;
    if (session == null) return "There's no current session to save into.";
    if (closed) return _closedNote;
    if (!armSubjectsReady(armId)) return 'Still checking this arm.';
    try {
      final existing = assignmentFor(armId, subjectId);
      if (existing?.staffId != staff.id) {
        if (existing == null) {
          await _subjects.addTeachingAssignment(
            organizationId: school.id,
            sessionId: session.id,
            armId: armId,
            subjectId: subjectId,
            staffId: staff.id,
          );
        } else {
          await _subjects.changeTeachingAssignmentTeacher(
            existing,
            staffId: staff.id,
          );
        }
        _changed = true;
      }
      _armAssignments.remove(armId);
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.saveSubject',
        showErrorModal: false,
      );
      // Someone may have set it first; read the arm again for the next try.
      _armAssignments.remove(armId);
      unawaited(loadArmSubjects(armId));
      return messageFor(error, "Couldn't set the subject. Try again.");
    } finally {
      notifyListeners();
    }
  }

  static const _closedNote =
      'This session is closed. Reopen it to change who teaches where.';

  static String _and(List<String> names) => switch (names.length) {
    0 => '',
    1 => names.first,
    _ => '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
  };

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
