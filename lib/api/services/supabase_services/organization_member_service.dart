import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationMemberService {
  OrganizationMemberService(this._supabase);

  final SupabaseClient _supabase;

  Future<bool> hasMembership(String clerkUserId) async {
    final row = await _supabase
        .from('organization_members')
        .select('id')
        .eq('clerk_user_id', clerkUserId)
        .limit(1)
        .maybeSingle();

    return row != null;
  }
}
