import 'package:realm/realm.dart';

import '../api/models/supabase_models/student_model.dart';
import 'models/student_realm.dart';
import 'realm_service.dart';

/// Bundle returned by [FamilyRealmService.parentsOf]/[studentsOf] so the
/// caller gets the joined entity *and* the relationship metadata in one go.
typedef ParentOfStudent = ({StudentParentLink link, ParentModel parent});
typedef StudentOfParent = ({StudentParentLink link, StudentModel student});

/// Unified offline cache for students, parents, and the link rows between
/// them. Keeping the three tables behind one service is what makes
/// `student → parents` and `parent → students` lookups work the same way
/// online and offline.
class FamilyRealmService {
  FamilyRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  // ─── Writes ──────────────────────────────────────────────────────────

  Future<void> saveStudents(List<StudentModel> items) async {
    if (items.isEmpty) return;
    final now = DateTime.now();
    _realm.write(() {
      for (final item in items) {
        if (item.id == null) continue;
        _realm.add(_studentToRealm(item, lastUpdated: now), update: true);
      }
    });
  }

  Future<void> saveStudent(StudentModel item) => saveStudents([item]);

  Future<void> saveParents(List<ParentModel> items) async {
    if (items.isEmpty) return;
    final now = DateTime.now();
    _realm.write(() {
      for (final item in items) {
        if (item.id == null) continue;
        _realm.add(_parentToRealm(item, lastUpdated: now), update: true);
      }
    });
  }

  Future<void> saveParent(ParentModel item) => saveParents([item]);

  Future<void> saveStudentParentLinks(List<StudentParentLink> links) async {
    if (links.isEmpty) return;
    final now = DateTime.now();
    _realm.write(() {
      for (final l in links) {
        _realm.add(_linkToRealm(l, lastUpdated: now), update: true);
      }
    });
  }

  /// Replaces all link rows for [studentId] with [links] in a single write.
  /// Use this after fetching a student's family from the server so the
  /// cache reflects exactly what the server has.
  Future<void> replaceLinksForStudent(
    String studentId,
    List<StudentParentLink> links,
  ) async {
    final now = DateTime.now();
    _realm.write(() {
      final stale = _realm
          .all<StudentParentLinkRealm>()
          .query("studentId == \$0", [studentId]);
      _realm.deleteMany(stale);
      for (final l in links) {
        _realm.add(_linkToRealm(l, lastUpdated: now), update: true);
      }
    });
  }

  // ─── Reads: singles + bulk ───────────────────────────────────────────

  StudentRealm? getStudent(String id) => _realm.find<StudentRealm>(id);
  ParentRealm?  getParent(String id)  => _realm.find<ParentRealm>(id);

  List<StudentRealm> getAllStudents() {
    final list = _realm.all<StudentRealm>().toList();
    list.sort((a, b) => a.lastName.compareTo(b.lastName));
    return list;
  }

  List<ParentRealm> getAllParents() {
    final list = _realm.all<ParentRealm>().toList();
    list.sort((a, b) => a.lastName.compareTo(b.lastName));
    return list;
  }

  List<StudentRealm> getStudentsByClass(String classId) {
    return _realm
        .all<StudentRealm>()
        .query("classId == \$0", [classId])
        .toList();
  }

  bool hasStudents() => _realm.all<StudentRealm>().isNotEmpty;
  bool hasParents()  => _realm.all<ParentRealm>().isNotEmpty;

  // ─── Reads: family traversal ─────────────────────────────────────────

  /// Parents linked to [studentId] with their relationship metadata.
  /// Returns an empty list if the student isn't cached or has no links.
  List<ParentOfStudent> parentsOf(String studentId) {
    final linkRows = _realm
        .all<StudentParentLinkRealm>()
        .query("studentId == \$0", [studentId])
        .toList();
    final result = <ParentOfStudent>[];
    for (final l in linkRows) {
      final parentRealm = _realm.find<ParentRealm>(l.parentId);
      if (parentRealm == null) continue;
      result.add((
        link: _linkFromRealm(l),
        parent: _parentFromRealm(parentRealm),
      ));
    }
    // Primary contact first, then by parent last_name for stable ordering.
    result.sort((a, b) {
      if (a.link.isPrimary != b.link.isPrimary) {
        return a.link.isPrimary ? -1 : 1;
      }
      return a.parent.lastName.toLowerCase().compareTo(
            b.parent.lastName.toLowerCase(),
          );
    });
    return result;
  }

  /// Students linked to [parentId] with their relationship metadata.
  List<StudentOfParent> studentsOf(String parentId) {
    final linkRows = _realm
        .all<StudentParentLinkRealm>()
        .query("parentId == \$0", [parentId])
        .toList();
    final result = <StudentOfParent>[];
    for (final l in linkRows) {
      final studentRealm = _realm.find<StudentRealm>(l.studentId);
      if (studentRealm == null) continue;
      result.add((
        link: _linkFromRealm(l),
        student: _studentFromRealm(studentRealm),
      ));
    }
    result.sort(
      (a, b) => a.student.lastName.toLowerCase().compareTo(
        b.student.lastName.toLowerCase(),
      ),
    );
    return result;
  }

  // ─── Deletes ─────────────────────────────────────────────────────────

  Future<void> deleteStudent(String id) async {
    final obj = _realm.find<StudentRealm>(id);
    if (obj == null) return;
    _realm.write(() {
      // Cascade: remove that student's link rows too.
      final links = _realm
          .all<StudentParentLinkRealm>()
          .query("studentId == \$0", [id]);
      _realm.deleteMany(links);
      _realm.delete(obj);
    });
  }

  Future<void> deleteParent(String id) async {
    final obj = _realm.find<ParentRealm>(id);
    if (obj == null) return;
    _realm.write(() {
      final links = _realm
          .all<StudentParentLinkRealm>()
          .query("parentId == \$0", [id]);
      _realm.deleteMany(links);
      _realm.delete(obj);
    });
  }

  Future<void> deleteLink(String linkId) async {
    final obj = _realm.find<StudentParentLinkRealm>(linkId);
    if (obj == null) return;
    _realm.write(() => _realm.delete(obj));
  }

  Future<void> deleteAll() async {
    _realm.write(() {
      _realm.deleteAll<StudentParentLinkRealm>();
      _realm.deleteAll<StudentRealm>();
      _realm.deleteAll<ParentRealm>();
    });
  }

  // ─── Mapping helpers ─────────────────────────────────────────────────

  StudentRealm _studentToRealm(
    StudentModel item, {
    required DateTime lastUpdated,
  }) {
    return StudentRealm(
      item.id!,
      item.firstName,
      item.lastName,
      item.isActive,
      email: item.email,
      phone: item.phone,
      gender: item.gender,
      dateOfBirth: item.dateOfBirth,
      admissionNumber: item.admissionNumber,
      admissionDate: item.admissionDate,
      address: item.address,
      state: item.state,
      avatarUrl: item.avatarUrl,
      avatarUrlId: item.avatarUrlId,
      fcmToken: item.fcmToken,
      classId: item.classId,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      lastUpdated: lastUpdated,
    );
  }

  StudentModel _studentFromRealm(StudentRealm r) => StudentModel(
        id: r.id,
        firstName: r.firstName,
        lastName: r.lastName,
        email: r.email,
        phone: r.phone,
        gender: r.gender,
        dateOfBirth: r.dateOfBirth,
        admissionNumber: r.admissionNumber,
        admissionDate: r.admissionDate,
        address: r.address,
        state: r.state,
        avatarUrl: r.avatarUrl,
        avatarUrlId: r.avatarUrlId,
        fcmToken: r.fcmToken,
        isActive: r.isActive,
        classId: r.classId,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  ParentRealm _parentToRealm(
    ParentModel item, {
    required DateTime lastUpdated,
  }) {
    return ParentRealm(
      item.id!,
      item.firstName,
      item.lastName,
      item.isActive,
      email: item.email,
      phone: item.phone,
      gender: item.gender,
      address: item.address,
      state: item.state,
      avatarUrl: item.avatarUrl,
      avatarUrlId: item.avatarUrlId,
      fcmToken: item.fcmToken,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      lastUpdated: lastUpdated,
    );
  }

  ParentModel _parentFromRealm(ParentRealm r) => ParentModel(
        id: r.id,
        firstName: r.firstName,
        lastName: r.lastName,
        email: r.email,
        phone: r.phone,
        gender: r.gender,
        address: r.address,
        state: r.state,
        avatarUrl: r.avatarUrl,
        avatarUrlId: r.avatarUrlId,
        fcmToken: r.fcmToken,
        isActive: r.isActive,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  StudentParentLinkRealm _linkToRealm(
    StudentParentLink item, {
    required DateTime lastUpdated,
  }) {
    return StudentParentLinkRealm(
      item.id,
      item.studentId,
      item.parentId,
      item.relationship,
      item.isPrimary,
      createdAt: item.createdAt,
      lastUpdated: lastUpdated,
    );
  }

  StudentParentLink _linkFromRealm(StudentParentLinkRealm r) =>
      StudentParentLink(
        id: r.id,
        studentId: r.studentId,
        parentId: r.parentId,
        relationship: r.relationship,
        isPrimary: r.isPrimary,
        createdAt: r.createdAt,
      );

  // Public conversion shims for callers (e.g. services returning model lists).
  StudentModel studentModelFromRealm(StudentRealm r) => _studentFromRealm(r);
  ParentModel  parentModelFromRealm(ParentRealm r)   => _parentFromRealm(r);
  StudentParentLink linkModelFromRealm(StudentParentLinkRealm r) =>
      _linkFromRealm(r);
}
