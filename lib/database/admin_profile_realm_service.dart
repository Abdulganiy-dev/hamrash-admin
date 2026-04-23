import 'package:realm/realm.dart';

import '../api/models/supabase_models/admin_profile_model.dart';
import 'models/admin_profile_realm.dart';
import 'realm_service.dart';

/// Realm-only storage for the signed-in admin's `public.admin_profiles` row.
///
/// Only a single profile is cached at a time; saving a new profile replaces
/// any previously stored one.
class AdminProfileRealmService {
  AdminProfileRealmService(this._realmService);

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  AdminProfileRealm _toRealm(AdminProfileModel m, DateTime now) {
    return AdminProfileRealm(
      m.id ?? '',
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

  /// Saves the given profile, replacing any previously cached profile so
  /// that Realm always holds at most one admin profile.
  Future<void> saveAdminProfile(AdminProfileModel item) async {
    _realm.write(() {
      _realm.deleteAll<AdminProfileRealm>();
      _realm.add(_toRealm(item, DateTime.now()));
    });
  }

  AdminProfileRealm? getAdminProfile() {
    final all = _realm.all<AdminProfileRealm>();
    if (all.isEmpty) return null;
    return all.first;
  }

  AdminProfileRealm? getAdminProfileByClerkId(String clerkId) {
    final profile = getAdminProfile();
    if (profile == null) return null;
    if (profile.clerkId != clerkId) return null;
    return profile;
  }

  bool hasAdminProfile() {
    return _realm.all<AdminProfileRealm>().isNotEmpty;
  }

  Future<void> deleteAdminProfile() async {
    _realm.write(() {
      _realm.deleteAll<AdminProfileRealm>();
    });
  }
}
