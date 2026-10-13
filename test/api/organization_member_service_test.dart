import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/claim_code_check.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/organization_member_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'calls the check and redeem RPCs with the schema argument names',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        accessToken: () async => 'clerk-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/check_claim_code')) {
            return http.Response(
              jsonEncode({
                'status': 'ok',
                'organization_id': 'org-1',
                'school_name': 'Kings College',
                'school_code': 'HMR-123456',
                'school_address': 'Ikeja',
                'school_state': 'Lagos',
                'school_logo_url': null,
                'role': 'owner',
                'app': 'admin',
                'needs_name': true,
                'tries_left': 5,
                'retry_at': null,
              }),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'member-1',
              'organization_id': 'org-1',
              'clerk_user_id': 'user-1',
              'role': 'owner',
              'status': 'active',
              'claim_code': null,
              'invited_by': null,
              'joined_at': '2026-10-13T14:00:00Z',
              'created_at': '2026-10-13T13:00:00Z',
              'updated_at': '2026-10-13T14:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final service = OrganizationMemberService(client);

      final checked = await service.checkClaimCode('KQ7M-2X9B');
      expect(checked.status, ClaimCodeStatus.ok);
      expect(checked.needsName, isTrue);
      expect(checked.role, OrganizationMemberRole.owner);

      final member = await service.redeemClaimCode(
        code: 'KQ7M-2X9B',
        firstName: 'Amina',
        lastName: 'Bello',
        email: 'amina@example.com',
        phone: '+2348030000000',
      );
      expect(member?.status, OrganizationMemberStatus.active);
      expect(requests, hasLength(2));
      expect(requests[0].url.path, '/rest/v1/rpc/check_claim_code');
      expect(jsonDecode(requests[0].body), {'p_code': 'KQ7M-2X9B'});
      expect(requests[1].url.path, '/rest/v1/rpc/redeem_claim_code');
      expect(jsonDecode(requests[1].body), {
        'p_code': 'KQ7M-2X9B',
        'p_first_name': 'Amina',
        'p_last_name': 'Bello',
        'p_email': 'amina@example.com',
        'p_phone': '+2348030000000',
      });
      expect(requests[0].headers['authorization'], 'Bearer clerk-token');
    },
  );

  test('a used claim code returns no membership', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);

    final member = await OrganizationMemberService(
      client,
    ).redeemClaimCode(code: 'KQ7M-2X9B');
    expect(member, isNull);
  });
}
