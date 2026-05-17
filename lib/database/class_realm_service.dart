import 'package:realm/realm.dart';

import '../api/models/supabase_models/class_model.dart';
import 'models/class_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for `public.classes` (Pattern 1 cache).
class ClassRealmService {
  ClassRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  Future<void> saveClasses(List<ClassModel> items) async {
    _realm.write(() {
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(
          ClassRealm(
            item.id ?? '',
            item.name,
            item.isActive,
            section: item.section,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            lastUpdated: now,
          ),
          update: true,
        );
      }
    });
  }

  Future<void> saveClass(ClassModel item) async {
    _realm.write(() {
      _realm.add(
        ClassRealm(
          item.id ?? '',
          item.name,
          item.isActive,
          section: item.section,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          lastUpdated: DateTime.now(),
        ),
        update: true,
      );
    });
  }

  List<ClassRealm> getAllClasses() {
    final list = _realm.all<ClassRealm>().toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  ClassRealm? getClassById(String id) {
    return _realm.find<ClassRealm>(id);
  }

  bool hasClasses() => _realm.all<ClassRealm>().isNotEmpty;

  Future<void> deleteClass(String id) async {
    final obj = _realm.find<ClassRealm>(id);
    if (obj != null) {
      _realm.write(() => _realm.delete(obj));
    }
  }

  Future<void> deleteAllClasses() async {
    _realm.write(() => _realm.deleteAll<ClassRealm>());
  }
}
