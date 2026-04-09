import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/models/app_role_realm.dart';
import '../../../database/role_realm_service.dart';
import '../../../models/role_model.dart';

/// Supabase + Realm cache-first for `public.roles` (Pattern 1).
class RoleService {
  RoleService({required RoleRealmService roleRealmService})
      : _roleRealmService = roleRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final RoleRealmService _roleRealmService;

  Future<List<RoleModel>> fetchRoles() async {
    try {
      if (_roleRealmService.hasRolesInRealm()) {
        return _roleRealmService
            .getRolesFromRealm()
            .map(_fromRealm)
            .toList();
      }

      final response = await _supabase
          .from('roles')
          .select()
          .order('name', ascending: true);

      final rows = response as List<dynamic>;
      final roles = rows
          .map((e) => RoleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (roles.isNotEmpty) {
        await _roleRealmService.saveRoles(roles);
      }

      return roles;
    } catch (_) {
      if (_roleRealmService.hasRolesInRealm()) {
        return _roleRealmService
            .getRolesFromRealm()
            .map(_fromRealm)
            .toList();
      }
      rethrow;
    }
  }

  RoleModel _fromRealm(AppRoleRealm r) {
    return RoleModel(
      id: r.id,
      name: r.name,
      description: r.description,
      createdAt: r.createdAt,
    );
  }
}
