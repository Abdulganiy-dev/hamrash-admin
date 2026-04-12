import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/admin_profile_realm_service.dart';
import '../../../database/models/admin_profile_realm.dart';
import '../../models/supabase_models/admin_profile_model.dart';

/// Supabase + Realm for `public.admin_profiles`.
///
/// List fetch: Pattern 2 (online-first, Realm fallback).
/// Mutations: Pattern 3 (write-through — cache mirrors server response).
class AdminProfileService {
  AdminProfileService({required AdminProfileRealmService adminProfileRealmService})
      : _realmService = adminProfileRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final AdminProfileRealmService _realmService;

  static const Duration _networkTimeout = Duration(seconds: 15);

  /// Fetches all profiles visible under RLS; replaces Realm cache on success.
  Future<List<AdminProfileModel>> fetchAdminProfiles() async {
    try {
      final response = await _supabase
          .from('admin_profiles')
          .select()
          .order('created_at', ascending: false)
          .timeout(_networkTimeout);

      final rows = response as List<dynamic>;
      final list = rows
          .map(
            (e) =>
                AdminProfileModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (list.isNotEmpty) {
        await _realmService.replaceAllAdminProfiles(list);
      } else {
        await _realmService.deleteAllAdminProfiles();
      }

      return list;
    } catch (_) {
      if (_realmService.hasAdminProfilesInRealm()) {
        return _realmService
            .getAdminProfilesFromRealm()
            .map(_fromRealm)
            .toList();
      }
      rethrow;
    }
  }

  /// Fetches a single profile by Clerk `sub`; upserts into Realm on success.
  Future<AdminProfileModel?> fetchAdminProfileByClerkId(String clerkId) async {
    try {
      final row = await _supabase
          .from('admin_profiles')
          .select()
          .eq('clerk_id', clerkId)
          .maybeSingle()
          .timeout(_networkTimeout);

      if (row == null) return null;

      final model =
          AdminProfileModel.fromJson(Map<String, dynamic>.from(row));
      await _realmService.saveAdminProfiles([model]);
      return model;
    } catch (_) {
      final cached = _realmService.getAdminProfileByClerkId(clerkId);
      if (cached != null) return _fromRealm(cached);
      rethrow;
    }
  }

  /// Pattern 3 — returns the row Supabase accepted.
  Future<AdminProfileModel> updateAdminProfile({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    final row = await _supabase
        .from('admin_profiles')
        .update(patch)
        .eq('id', id)
        .select()
        .single();

    final model =
        AdminProfileModel.fromJson(Map<String, dynamic>.from(row));
    await _realmService.saveAdminProfiles([model]);
    return model;
  }

  /// Pattern 3 — returns the inserted row from Supabase.
  Future<AdminProfileModel> insertAdminProfile(
    Map<String, dynamic> row,
  ) async {
    final inserted = await _supabase
        .from('admin_profiles')
        .insert(row)
        .select()
        .single();

    final model =
        AdminProfileModel.fromJson(Map<String, dynamic>.from(inserted));
    await _realmService.saveAdminProfiles([model]);
    return model;
  }

  AdminProfileModel _fromRealm(AdminProfileRealm r) {
    return AdminProfileModel(
      id: r.id,
      clerkId: r.clerkId,
      fullName: r.fullName,
      email: r.email,
      phoneNumber: r.phoneNumber,
      gender: r.gender,
      avatarUrl: r.avatarUrl,
      avatarUrlId: r.avatarUrlId,
      address: r.address,
      state: r.stateText,
      fcmToken: r.fcmToken,
      role: r.role,
      isActive: r.isActive,
      lastLoginAt: r.lastLoginAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
