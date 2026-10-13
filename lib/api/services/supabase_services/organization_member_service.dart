import 'dart:convert';

import 'package:hamrash_admin/api/models/organization_models/claim_code_check.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/core/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationMemberService {
  OrganizationMemberService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<OrganizationMember>> getMembershipsWithOrganizations(
    String clerkUserId,
  ) async {
    try {
      final rows = await _supabase
          .from('organization_members')
          .select('*, organization:organizations(*)')
          .eq('clerk_user_id', clerkUserId);

      final memberships = rows
          .map(
            (row) =>
                OrganizationMember.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);

      AppLogger.info(
        'Supabase getMembershipsWithOrganizations result: '
        '${jsonEncode(memberships.map(_membershipLogResult).toList())}',
      );
      return memberships;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Supabase getMembershipsWithOrganizations failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ClaimCodeCheck> checkClaimCode(String code) async {
    try {
      final row = await _supabase
          .rpc('check_claim_code', params: {'p_code': code})
          .single();

      final result = ClaimCodeCheck.fromJson(Map<String, dynamic>.from(row));
      AppLogger.info(
        'Supabase checkClaimCode result: ${jsonEncode({'status': result.status.value, 'organization_id': result.organizationId, 'school_name': result.schoolName, 'school_code': result.schoolCode, 'school_address': result.schoolAddress, 'school_state': result.schoolState, 'school_logo_url': result.schoolLogoUrl, 'role': result.role?.value, 'app': result.app, 'needs_name': result.needsName, 'tries_left': result.triesLeft, 'retry_at': result.retryAt?.toIso8601String()})}',
      );
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Supabase checkClaimCode failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<OrganizationMember?> redeemClaimCode({
    required String code,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      final row = await _supabase.rpc(
        'redeem_claim_code',
        params: {
          'p_code': code,
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_email': email,
          'p_phone': phone,
        },
      );

      if (row == null) {
        AppLogger.info('Supabase redeemClaimCode result: null');
        return null;
      }

      final membership = OrganizationMember.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      AppLogger.info(
        'Supabase redeemClaimCode result: '
        '${jsonEncode(_membershipLogResult(membership))}',
      );
      return membership;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Supabase redeemClaimCode failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, Object?> _membershipLogResult(OrganizationMember member) => {
    'id': member.id,
    'organization_id': member.organizationId,
    'organization_name': member.organization?.name,
    'organization_code': member.organization?.code,
    'organization_status': member.organization?.status.value,
    'role': member.role.value,
    'status': member.status.value,
    'joined_at': member.joinedAt?.toIso8601String(),
  };
}
