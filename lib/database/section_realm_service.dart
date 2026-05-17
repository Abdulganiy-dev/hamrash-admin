import 'package:realm/realm.dart';

import '../api/models/supabase_models/section_model.dart';
import 'models/section_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for `public.sections` (Pattern 1 cache).
class SectionRealmService {
  SectionRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  Future<void> saveSections(List<SectionModel> items) async {
    _realm.write(() {
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(
          SectionRealm(
            item.id ?? '',
            item.name,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            lastUpdated: now,
          ),
          update: true,
        );
      }
    });
  }

  Future<void> saveSection(SectionModel item) async {
    _realm.write(() {
      _realm.add(
        SectionRealm(
          item.id ?? '',
          item.name,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          lastUpdated: DateTime.now(),
        ),
        update: true,
      );
    });
  }

  List<SectionRealm> getAllSections() {
    final list = _realm.all<SectionRealm>().toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  SectionRealm? getSectionById(String id) {
    return _realm.find<SectionRealm>(id);
  }

  bool hasSections() => _realm.all<SectionRealm>().isNotEmpty;

  Future<void> deleteSection(String id) async {
    final obj = _realm.find<SectionRealm>(id);
    if (obj != null) {
      _realm.write(() => _realm.delete(obj));
    }
  }

  Future<void> deleteAllSections() async {
    _realm.write(() => _realm.deleteAll<SectionRealm>());
  }
}
