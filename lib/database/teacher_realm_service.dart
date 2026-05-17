import 'package:realm/realm.dart';

import '../api/models/supabase_models/teacher_model.dart';
import 'models/teacher_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for `public.teachers` (Pattern 1 cache).
class TeacherRealmService {
  TeacherRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  Future<void> saveTeachers(List<TeacherModel> items) async {
    _realm.write(() {
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(_toRealm(item, lastUpdated: now), update: true);
      }
    });
  }

  Future<void> saveTeacher(TeacherModel item) async {
    _realm.write(() {
      _realm.add(_toRealm(item, lastUpdated: DateTime.now()), update: true);
    });
  }

  List<TeacherRealm> getAllTeachers() {
    final list = _realm.all<TeacherRealm>().toList();
    list.sort((a, b) => a.lastName.compareTo(b.lastName));
    return list;
  }

  TeacherRealm? getTeacherById(String id) {
    return _realm.find<TeacherRealm>(id);
  }

  bool hasTeachers() => _realm.all<TeacherRealm>().isNotEmpty;

  Future<void> deleteTeacher(String id) async {
    final obj = _realm.find<TeacherRealm>(id);
    if (obj != null) {
      _realm.write(() => _realm.delete(obj));
    }
  }

  Future<void> deleteAllTeachers() async {
    _realm.write(() => _realm.deleteAll<TeacherRealm>());
  }

  TeacherRealm _toRealm(TeacherModel item, {required DateTime lastUpdated}) {
    return TeacherRealm(
      item.id ?? '',
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
      homeroomClassId: item.homeroomClassId,
      homeroomRole: item.homeroomRole,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      lastUpdated: lastUpdated,
    );
  }
}
