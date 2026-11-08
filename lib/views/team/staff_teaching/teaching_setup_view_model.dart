import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

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

/// The teaching setup behind one staff member: their homeroom, the subject
/// sheet's pickers, and the two writes. Everything the sheets need is read
/// once, so each choice can say what saving it would do before the tap.
///
/// Writes return the reason they failed (null when saved), the database's
/// message when it refused, see [SupabaseRefusal].
class TeachingSetupViewModel extends BaseViewModel {
  TeachingSetupViewModel({
    required this.school,
    required this.staff,
    ClassStructureService? structure,
    SubjectService? subjects,
  }) : _structure = structure ?? locator<ClassStructureService>(),
       _subjects = subjects ?? locator<SubjectService>();

  final MemberSchool school;
  final StaffMember staff;
  final ClassStructureService _structure;
  final SubjectService _subjects;

  AcademicSession? _session;
  List<SchoolSection> _sections = const [];
  List<Subject> _subjectsList = const [];
  List<ArmSubject> _links = const [];
  List<ClassTeacher> _classTeachers = const [];
  List<ClassTeacher> _staffRows = const [];
  List<TeachingAssignment> _assignments = const [];
  List<TeachingAssignment> _staffAssignments = const [];
  Object? _error;
  bool _loaded = false;
  bool _changed = false;

  AcademicSession? get session => _session;
  Object? get error => _error;
  bool get loading => !_loaded && _error == null;

  /// Something was saved, so the staff page should reload.
  bool get changed => _changed;

  bool get hasSession => _session != null;

  /// A closed session is read-only; the database refuses every write.
  bool get closed => _session?.isClosed ?? false;

  /// "2026/27".
  String get schoolYear => _session?.name ?? '';

  /// "Ngozi Eze".
  String get staffName => staff.fullName;

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

  /// The class [armId] belongs to, or null when it is gone or switched off.
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

  /// The arm with [armId], or null when it is gone or switched off.
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
    for (final row in _staffRows) {
      if (row.isLead) return row;
    }
    return _staffRows.isEmpty ? null : _staffRows.first;
  }

  /// "{Class}{Arm} · Lead teacher", or "Not set".
  String get homeroomCaption {
    final row = homeroom;
    if (row == null) return 'Not set';
    final role = row.isLead ? 'Lead teacher' : 'Assistant teacher';
    return '${row.armLabel} · $role';
  }

  /// How many subjects the staff member teaches this session.
  int get subjectCount => _staffAssignments.length;

  /// "3 subjects this session", or "None this session".
  String get subjectCaption {
    if (subjectCount == 0) return 'None this session';
    final noun = subjectCount == 1 ? 'subject' : 'subjects';
    return '$subjectCount $noun this session';
  }

  /// The lead of [armId], or null when nobody leads it yet.
  ClassTeacher? leadOf(String armId) {
    for (final row in _classTeachers) {
      if (row.armId == armId && row.isLead) return row;
    }
    return null;
  }

  /// The assistants of [armId] this session.
  List<ClassTeacher> assistantsOf(String armId) => [
    for (final row in _classTeachers)
      if (row.armId == armId && !row.isLead) row,
  ];

  /// "Lead · Ngozi Eze", or "No lead yet".
  String armCaption(String armId) {
    final lead = leadOf(armId);
    return lead == null ? 'No lead yet' : 'Lead · ${lead.staffName}';
  }

  /// subject id → compulsory, for [armId]'s curriculum.
  Map<String, bool> curriculumOf(String armId) {
    final curriculum = <String, bool>{};
    for (final link in _links) {
      if (link.armId == armId) curriculum[link.subjectId] = link.isCompulsory;
    }
    return curriculum;
  }

  /// The subjects on [armId]'s curriculum, in report-card order.
  List<Subject> subjectsOn(String armId) {
    final curriculum = curriculumOf(armId);
    return [
      for (final subject in _subjectsList)
        if (curriculum.containsKey(subject.id)) subject,
    ];
  }

  /// "Compulsory" or "Choice", for the subject picker's caption.
  String subjectCaptionFor(String armId, Subject subject) =>
      curriculumOf(armId)[subject.id] == true ? 'Compulsory' : 'Choice';

  Subject? subjectById(String? subjectId) {
    if (subjectId == null) return null;
    for (final subject in _subjectsList) {
      if (subject.id == subjectId) return subject;
    }
    return null;
  }

  /// The teacher set for [subjectId] in [armId] this session, if anyone.
  TeachingAssignment? assignmentFor(String armId, String subjectId) {
    for (final row in _assignments) {
      if (row.armId == armId && row.subjectId == subjectId) return row;
    }
    return null;
  }

  /// The class teacher row for [staffId] on [armId], if any.
  ClassTeacher? classTeacherFor(String armId, String staffId) {
    for (final row in _classTeachers) {
      if (row.armId == armId && row.staffId == staffId) return row;
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
    if (curriculumOf(armId).isEmpty) {
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
    final name = subjectById(subjectId)?.name ?? '';
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
        context: 'TeachingSetup.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Re-reads everything, e.g. after subjects were added to an arm.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Makes [staffId] the lead or an assistant of [armId]. Updates the row
  /// when they are already on the arm, otherwise inserts one. Returns the
  /// reason it failed, or null when it saved.
  Future<String?> saveHomeroom({
    required String armId,
    required bool isLead,
  }) async {
    final session = _session;
    if (session == null) return "There's no current session to save into.";
    if (closed) return _closedNote;
    try {
      final roster = await _structure.listClassTeachers(
        organizationId: school.id,
        sessionId: session.id,
        armId: armId,
      );
      ClassTeacher? existing;
      for (final row in roster) {
        if (row.staffId == staff.id) existing = row;
      }
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
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.saveHomeroom',
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
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
    try {
      final existing = await _subjects.getTeachingAssignment(
        organizationId: school.id,
        sessionId: session.id,
        armId: armId,
        subjectId: subjectId,
      );
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
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'TeachingSetup.saveSubject',
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return messageFor(error, "Couldn't set the subject. Try again.");
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetch() async {
    final session = await _structure.getCurrentSession(school.id);
    if (session == null) {
      _session = null;
      _sections = const [];
      _subjectsList = const [];
      _links = const [];
      _classTeachers = const [];
      _staffRows = const [];
      _assignments = const [];
      _staffAssignments = const [];
      _loaded = true;
      return;
    }
    final results = await Future.wait<Object?>([
      _structure.getStructure(school.id),
      _structure.listClassTeachers(
        organizationId: school.id,
        sessionId: session.id,
      ),
      _structure.getStaffClassTeachers(
        organizationId: school.id,
        staffId: staff.id,
        sessionId: session.id,
      ),
      _subjects.listSubjects(school.id),
      _subjects.listArmSubjects(school.id),
      _subjects.listTeachingAssignments(
        organizationId: school.id,
        sessionId: session.id,
      ),
      _subjects.listStaffTeachingAssignments(
        organizationId: school.id,
        staffId: staff.id,
        sessionId: session.id,
      ),
    ]);
    _session = session;
    _sections = results[0]! as List<SchoolSection>;
    _classTeachers = results[1]! as List<ClassTeacher>;
    _staffRows = results[2]! as List<ClassTeacher>;
    _subjectsList = results[3]! as List<Subject>;
    _links = results[4]! as List<ArmSubject>;
    _assignments = results[5]! as List<TeachingAssignment>;
    _staffAssignments = results[6]! as List<TeachingAssignment>;
    _loaded = true;
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
