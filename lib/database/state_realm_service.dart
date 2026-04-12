import 'package:realm/realm.dart';

import '../api/models/supabase_models/state_model.dart';
import 'models/state_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for states — no Supabase imports (Pattern 1 cache).
class StateRealmService {
  StateRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  Future<void> saveStates(List<StateModel> items) async {
    _realm.write(() {
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(
          StateRealm(item.id, item.name, lastUpdated: now),
          update: true,
        );
      }
    });
  }

  List<StateRealm> getStatesFromRealm() {
    final list = _realm.all<StateRealm>().toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  bool hasStatesInRealm() {
    return _realm.all<StateRealm>().isNotEmpty;
  }

  Future<void> deleteAllStates() async {
    _realm.write(() {
      _realm.deleteAll<StateRealm>();
    });
  }
}
