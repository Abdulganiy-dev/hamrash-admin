import 'package:realm/realm.dart';

import '../api/models/supabase_models/class_model.dart';
import 'models/subject_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for `public.subjects` (Pattern 1 cache).
class SubjectRealmService {
  SubjectRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  Future<void> saveSubjects(List<SubjectModel> items) async {
    _realm.write(() {
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(
          SubjectRealm(
            item.id ?? '',
            item.name,
            item.isActive,
            description: item.description,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            lastUpdated: now,
          ),
          update: true,
        );
      }
    });
  }

  Future<void> saveSubject(SubjectModel item) async {
    _realm.write(() {
      _realm.add(
        SubjectRealm(
          item.id ?? '',
          item.name,
          item.isActive,
          description: item.description,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          lastUpdated: DateTime.now(),
        ),
        update: true,
      );
    });
  }

  List<SubjectRealm> getAllSubjects() {
    final list = _realm.all<SubjectRealm>().toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  SubjectRealm? getSubjectById(String id) {
    return _realm.find<SubjectRealm>(id);
  }

  bool hasSubjects() => _realm.all<SubjectRealm>().isNotEmpty;

  Future<void> deleteSubject(String id) async {
    final obj = _realm.find<SubjectRealm>(id);
    if (obj != null) {
      _realm.write(() => _realm.delete(obj));
    }
  }

  Future<void> deleteAllSubjects() async {
    _realm.write(() => _realm.deleteAll<SubjectRealm>());
  }
}
