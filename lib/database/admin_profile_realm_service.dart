import 'package:realm/realm.dart';

import '../models/admin_profile_model.dart';
import 'models/admin_profile_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for `public.admin_profiles`.
class AdminProfileRealmService {
  AdminProfileRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  AdminProfileRealm _toRealm(AdminProfileModel m, DateTime now) {
    return AdminProfileRealm(
      m.id,
      m.fullName,
      m.email,
      m.isActive,
      clerkId: m.clerkId,
      phoneNumber: m.phoneNumber,
      gender: m.gender,
      avatarUrl: m.avatarUrl,
      avatarUrlId: m.avatarUrlId,
      address: m.address,
      stateText: m.state,
      fcmToken: m.fcmToken,
      role: m.role,
      lastLoginAt: m.lastLoginAt,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
      lastUpdated: now,
    );
  }

  Future<void> saveAdminProfiles(List<AdminProfileModel> items) async {
    _realm.write(() {
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(_toRealm(item, now), update: true);
      }
    });
  }

  /// Replace local cache with a fresh list (e.g. after online fetch).
  Future<void> replaceAllAdminProfiles(List<AdminProfileModel> items) async {
    _realm.write(() {
      _realm.deleteAll<AdminProfileRealm>();
      final now = DateTime.now();
      for (final item in items) {
        _realm.add(_toRealm(item, now), update: true);
      }
    });
  }

  List<AdminProfileRealm> getAdminProfilesFromRealm() {
    final list = _realm.all<AdminProfileRealm>().toList();
    list.sort((a, b) {
      final ac = a.createdAt;
      final bc = b.createdAt;
      if (ac == null && bc == null) return a.fullName.compareTo(b.fullName);
      if (ac == null) return 1;
      if (bc == null) return -1;
      return bc.compareTo(ac);
    });
    return list;
  }

  AdminProfileRealm? getAdminProfileByClerkId(String clerkId) {
    final matches =
        _realm.query<AdminProfileRealm>('clerkId == \$0', [clerkId]).toList();
    if (matches.isEmpty) return null;
    return matches.first;
  }

  bool hasAdminProfilesInRealm() {
    return _realm.all<AdminProfileRealm>().isNotEmpty;
  }

  Future<void> deleteAllAdminProfiles() async {
    _realm.write(() {
      _realm.deleteAll<AdminProfileRealm>();
    });
  }
}
