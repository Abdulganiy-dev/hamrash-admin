import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationMemberService {
  OrganizationMemberService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<OrganizationMember>> getMembershipsWithOrganizations(
    String clerkUserId,
  ) async {
    final rows = await _supabase
        .from('organization_members')
        .select('*, organization:organizations(*)')
        .eq('clerk_user_id', clerkUserId);

    return rows
        .map(
          (row) => OrganizationMember.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }
}
