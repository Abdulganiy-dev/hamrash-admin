import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_details_changes.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';

/// 9.12 – 9.24 · One student. What the page offers follows who is looking:
/// leaders change things, a bursar only reads (9.12a), and only the owner and
/// admins manage the student's login or remove them.
///
/// Sheet saves return an error message (null when it worked); confirmed
/// actions throw [AppAlertError] for the confirm sheet to show. The message
/// is the database's reason when it refused, see [SupabaseRefusal].
class StudentDetailViewModel extends BaseViewModel {
  StudentDetailViewModel({
    required this.school,
    required this.studentId,
    StudentService? students,
    DateTime Function()? now,
  }) : _students = students ?? locator<StudentService>(),
       _now = now ?? DateTime.now;

  final MemberSchool school;
  final String studentId;
  final StudentService _students;
  final DateTime Function() _now;

  StudentProfile? _student;
  Object? _error;
  bool _changed = false;
  bool _removed = false;

  StudentProfile get student => _student!;
  Object? get error => _error;
  bool get loading => _student == null && _error == null;

  /// Something was saved, so the list behind should reload.
  bool get changed => _changed;

  /// The student was removed: the page closes.
  bool get removed => _removed;

  // ───────────────────────── who may do what ─────────────────────────

  /// Leaders change the student's record, class, subjects and parents.
  bool get canEdit => school.canRunSetup;

  /// Changes only make sense for a student still in school.
  bool get canChangeClass => canEdit && student.isActive;

  /// Leaders see the private details; so do the student's teachers (not in
  /// this app). A bursar's page stops at Details.
  bool get showPersonal => canEdit && student.isActive;

  /// The Access card holds the student's login and the status and remove
  /// actions.
  bool get showAccess => canEdit && student.isActive;

  /// Only the owner and admins suspend, restore, cancel an invite or remove.
  bool get canManageAccess => school.canManageAccess;

  /// Leaders issue the login.
  bool get canInvite =>
      canEdit && student.isActive && student.access == StudentAccess.notOnApp;

  // ───────────────────────── words ─────────────────────────

  /// "JSS 1B · KCL/2026/0021", or just the number with no class.
  String get identityMeta {
    final arm = student.placement?.armLabel;
    return arm == null
        ? student.admissionNumber
        : '$arm · ${student.admissionNumber}';
  }

  /// The pill under the name.
  String get statusLabel => student.status.label;

  /// "Withdrawn on 10 Nov 2026" for a student no longer in school.
  ///
  /// TODO(data): the student record keeps no separate date for its status, so
  /// this reads when the record last changed — the closest date the database
  /// keeps. Swap it when the status change is dated.
  String? get leftOnLabel {
    if (student.isActive) return null;
    return '${student.status.label} on '
        '${AppDateFormat.dayMonthYear(student.updatedAt ?? _now())}';
  }

  /// The line under the banner's title for a student who has left.
  String get leftExplanation {
    final arm = student.placement?.armLabel;
    final list = arm == null ? 'class lists' : 'the $arm list';
    return "They're off $list. Their results and parents stay on record.";
  }

  /// "2026/27" for the Class header, or "Last placed 2026/27" after they
  /// left.
  String? get classCaption {
    final session = student.placement?.sessionName;
    if (session == null) return null;
    return student.isActive ? session : 'Last placed $session';
  }

  /// "JSS 1B · Ibrahim Bello", or the arm alone with no lead teacher.
  String get classValue {
    final placement = student.placement;
    if (placement == null) return 'Not in a class this session';
    final lead = placement.leadTeacher;
    return lead == null ? placement.armLabel : '${placement.armLabel} · $lead';
  }

  /// "Subjects · 9 core, 2 optional".
  String get subjectsCaption {
    final placement = student.placement;
    if (placement == null) return 'Subjects';
    final core = placement.core.length;
    final optional = placement.chosen.length;
    return 'Subjects · $core core, $optional optional';
  }

  /// The optional subjects they take, or "No optional subjects".
  String get subjectsValue {
    final chosen = student.placement?.chosen ?? const [];
    return chosen.isEmpty
        ? 'No optional subjects'
        : chosen.map((offer) => offer.name).join(', ');
  }

  String get admittedLabel => student.admissionDate == null
      ? ''
      : AppDateFormat.dayMonthYear(student.admissionDate!);

  String get dateOfBirthLabel => student.details.dateOfBirth == null
      ? ''
      : AppDateFormat.dayMonthYear(student.details.dateOfBirth!);

  /// "Kano · Nassarawa": state then LGA, whichever are known.
  String get stateOfOriginLabel {
    final parts = [student.details.stateOfOrigin, student.details.lga]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    return parts.join(' · ');
  }

  String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? get address => _clean(student.details.address);
  String? get bloodGroup => _clean(student.details.bloodGroup);
  String? get genotype => _clean(student.details.genotype);
  String? get medicalNotes => _clean(student.details.medicalNotes);

  /// "Joined 3 Sep 2026" or "Invited 8 Nov", the Access card's caption.
  String? get accessCaption {
    final login = student.login;
    if (login == null) return null;
    return switch (student.access) {
      StudentAccess.codeReady =>
        'Invited ${AppDateFormat.dayMonth(login.createdAt)}',
      StudentAccess.onApp || StudentAccess.suspended =>
        login.joinedAt == null
            ? null
            : 'Joined ${AppDateFormat.dayMonthYear(login.joinedAt!)}',
      StudentAccess.notOnApp => null,
    };
  }

  /// The one app card: "Hamrash Student" with the login's state. Tapping it
  /// invites a student who isn't on the app yet, when [onInvite] is given.
  List<AccessApp> accessApps({VoidCallback? onInvite}) => [
    AccessApp(
      appName: 'Hamrash Student',
      state: switch (student.access) {
        StudentAccess.notOnApp => AccessState.notOnApp,
        StudentAccess.codeReady => AccessState.codeReady,
        StudentAccess.onApp => AccessState.onApp,
        StudentAccess.suspended => AccessState.suspended,
      },
      onTap: student.access == StudentAccess.notOnApp ? onInvite : null,
    ),
  ];

  /// The 9.23 sheet's words: the raw code and the message to send.
  String get rawCode => student.login?.claimCode ?? '';

  String shareMessage(String code) =>
      "Hi ${student.firstNameOnly}, ${school.name} has added you on Hamrash. "
      'Open the Hamrash student app, sign in with Apple or Google, and enter '
      '${_formatCode(code)}.';

  static String _formatCode(String raw) {
    final code = raw.replaceAll('-', '').toUpperCase();
    return code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;
  }

  String get currentShareMessage => shareMessage(rawCode);
  String get displayCode => _formatCode(rawCode);

  // ───────────────────────── 9.24 · remove ─────────────────────────

  String get removeTitle => 'Remove ${student.fullName}?';

  static const removeMessage =
      "Use this only if they were added by mistake. If they've left the "
      'school, change their status instead so their records stay.';

  /// The three things removing does.
  List<String> get removeBullets {
    final session = student.placement?.sessionName;
    return [
      session == null
          ? 'Their class place and subjects go'
          : 'Their class place and subjects for $session go',
      if (student.login != null)
        'Their student app login stops working',
      'Their parents stay, with any other children',
    ];
  }

  // ───────────────────────── loading ─────────────────────────

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
        context: 'StudentDetail.load',
        showErrorModal: false,
      );
    }
    if (!isDisposed) notifyListeners();
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
        context: 'StudentDetail.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> reload() async {
    await _fetch().catchError((_) {});
    if (!isDisposed) notifyListeners();
  }

  Future<void> _fetch() async {
    _student = await _students.getStudent(
      organizationId: school.id,
      studentId: studentId,
    );
  }

  // ───────────────────────── changes ─────────────────────────

  /// 9.14 · Saves the Change details sheet. Returns the reason it failed.
  Future<String?> saveDetails(StudentDetailsChanges changes) => _save(
    () => _students.updateStudentDetails(student: student, changes: changes),
    "Couldn't save the details. Try again.",
    'StudentDetail.saveDetails',
  );

  /// 9.21 · Changes their status.
  Future<String?> setStatus(StudentStatusFilter status) {
    if (status == student.status) return Future.value();
    return _save(
      () => _students.setStudentStatus(student: student, status: status),
      "Couldn't change the status. Try again.",
      'StudentDetail.setStatus',
    );
  }

  /// 9.15 · Moves them to [armId]. Returns how many optional subjects were
  /// dropped (0 when none) or the reason it failed.
  Future<({int dropped, String? error})> moveToArm(String armId) async {
    var dropped = 0;
    final error = await _save(() async {
      dropped = await _students.moveToArm(studentId: studentId, armId: armId);
    }, "Couldn't move them. Try again.", 'StudentDetail.moveToArm');
    return (dropped: dropped, error: error);
  }

  /// The arms of their class for the move sheet; null when they have no class.
  Future<List<ArmChoice>?> loadArmChoices() async {
    final placement = student.placement;
    if (placement == null) return null;
    return _students.listArmChoices(
      organizationId: school.id,
      classId: placement.classId,
      className: placement.className,
      sessionId: placement.sessionId,
    );
  }

  /// 9.16 · Saves exactly these optional subjects.
  Future<String?> saveOptionalSubjects(Set<String> subjectIds) {
    final placement = student.placement!;
    return _save(
      () => _students.setOptionalSubjects(
        organizationId: school.id,
        studentId: studentId,
        sessionId: placement.sessionId,
        current: placement.chosenOptionalIds,
        subjectIds: subjectIds,
      ),
      "Couldn't save the subjects. Try again.",
      'StudentDetail.saveOptionalSubjects',
    );
  }

  /// 9.23 · Makes the invite. Returns the raw code or the reason.
  Future<({String? code, String? error})> invite() async {
    String? code;
    final error = await _save(() async {
      code = await _students.inviteStudent(studentId);
    }, "Couldn't create the invite. Try again.", 'StudentDetail.invite');
    return (code: code, error: error);
  }

  Future<void> cancelInvite() => _act(
    () => _students.cancelInvite(student.login!.id),
    "Couldn't cancel the invite. Try again.",
  );

  Future<void> setSuspended(bool suspended) => _act(
    () => _students.setSuspended(
      memberId: student.login!.id,
      suspended: suspended,
    ),
    suspended
        ? "Couldn't suspend access. Try again."
        : "Couldn't restore access. Try again.",
  );

  /// 9.24 · Removes the student; the page then closes.
  Future<void> remove() async {
    await _act(
      () => _students.removeStudent(studentId),
      "Couldn't remove them. Try again.",
    );
    _removed = true;
  }

  // ───────────────────────── parents ─────────────────────────

  /// Whether a new parent would be the student's first, and so the primary
  /// contact.
  bool get nextParentIsPrimary => student.parents.isEmpty;

  /// Links a parent already at the school.
  Future<String?> linkParent(
    String parentId,
    ParentRelationship relationship,
  ) => _save(
    () => _students.linkParent(
      organizationId: school.id,
      studentId: studentId,
      parentId: parentId,
      relationship: relationship,
      primary: nextParentIsPrimary,
    ),
    "Couldn't add the parent. Try again.",
    'StudentDetail.linkParent',
  );

  /// The engine of the Add a parent sheet: the very same one the Add
  /// student flow uses (find by phone, found-parent row, the new parent form
  /// with its optional photo). It starts with the student's first name for
  /// "Relationship to Abdullahi" and with the parents they already have, so
  /// one of them is found as "already added" rather than linked twice.
  AddStudentViewModel parentSheetModel() {
    final sheet = AddStudentViewModel(school: school, students: _students);
    sheet.firstName.text = student.firstName;
    for (final parent in student.parents) {
      sheet.parents.add(
        AddedParent.existing(
          ParentMatch(
            id: parent.id,
            title: parent.title,
            firstName: parent.firstName,
            lastName: parent.lastName,
            phone: parent.phone,
          ),
          parent.relationship,
        ),
      );
    }
    return sheet;
  }

  /// Saves the parent the sheet just added: an existing parent is linked; a
  /// new one is created (with their photo, if one was uploaded) and linked.
  /// The first parent a student gets is their primary contact.
  Future<String?> addParentFrom(AddedParent added) => _save(
    () async {
      final match = added.match;
      if (match != null) {
        await _students.linkParent(
          organizationId: school.id,
          studentId: studentId,
          parentId: match.id,
          relationship: added.relationship,
          primary: nextParentIsPrimary,
        );
        return;
      }
      await _students.createAndLinkParent(
        organizationId: school.id,
        studentId: studentId,
        title: added.title,
        firstName: added.firstName,
        lastName: added.lastName,
        phone: added.phone,
        email: added.email ?? '',
        occupation: added.occupation ?? '',
        address: added.address ?? '',
        relationship: added.relationship,
        primary: nextParentIsPrimary,
        photoId: added.photo?.ready?.id,
        photoUrl: added.photo?.ready?.url,
      );
    },
    "Couldn't add the parent. Try again.",
    'StudentDetail.addParent',
  );

  Future<String?> changeRelationship(
    StudentParent parent,
    ParentRelationship relationship,
  ) => _save(
    () => _students.setParentRelationship(
      studentId: studentId,
      parentId: parent.id,
      relationship: relationship,
    ),
    "Couldn't change the relationship. Try again.",
    'StudentDetail.changeRelationship',
  );

  /// "They stop being Abdullahi's parent here and won't see their results.
  /// Mr Musa Yusuf becomes the primary contact."
  String unlinkMessage(StudentParent parent) {
    final next = _nextPrimary(parent);
    final base =
        "They stop being ${student.firstNameOnly}'s parent here and won't "
        'see their results.';
    return next == null ? base : '$base ${next.displayName} becomes the primary contact.';
  }

  /// Who takes over as primary contact if [parent] is unlinked: the next
  /// parent in the list, when [parent] was the primary.
  StudentParent? _nextPrimary(StudentParent parent) {
    if (!parent.isPrimaryContact) return null;
    for (final other in student.parents) {
      if (other.id != parent.id) return other;
    }
    return null;
  }

  Future<void> unlink(StudentParent parent) => _act(
    () => _students.unlinkParent(
      studentId: studentId,
      parentId: parent.id,
      newPrimaryId: _nextPrimary(parent)?.id,
    ),
    "Couldn't unlink them. Try again.",
  );

  /// A phone shown nationally, "0803 112 4455".
  String phoneLabel(String phone) => PhoneFormat.nationalDisplay(phone);

  // ───────────────────────── plumbing ─────────────────────────

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
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback, 'StudentDetail.action');
    if (message != null) throw AppAlertError(message);
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
