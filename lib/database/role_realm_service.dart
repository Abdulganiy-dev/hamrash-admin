import 'package:realm/realm.dart';

import '../api/models/supabase_models/role_model.dart';
import 'models/app_role_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for `public.roles` (Pattern 1).
class RoleRealmService {
  RoleRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  Future<void> saveRoles(List<RoleModel> items) async {
    _realm.write(() {
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(
          AppRoleRealm(
            item.id,
            item.name,
            description: item.description,
            createdAt: item.createdAt,
            lastUpdated: now,
          ),
          update: true,
        );
      }
    });
  }

  List<AppRoleRealm> getRolesFromRealm() {
    final list = _realm.all<AppRoleRealm>().toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  bool hasRolesInRealm() {
    return _realm.all<AppRoleRealm>().isNotEmpty;
  }

  Future<void> deleteAllRoles() async {
    _realm.write(() {
      _realm.deleteAll<AppRoleRealm>();
    });
  }
}
