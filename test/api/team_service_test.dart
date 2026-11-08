import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_details_changes.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

http.Response _json(Object body, http.Request request, {int status = 200}) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );

http.Response _refused(String code, http.Request request, String message) =>
    _json(
      {'code': code, 'message': message, 'details': null, 'hint': null},
      request,
      status: 400,
    );

(TeamService, List<http.Request>) _service(
  http.Response Function(http.Request request) respond,
) {
  final requests = <http.Request>[];
  final client = SupabaseClient(
    'https://example.supabase.co',
    'test-key',
    httpClient: MockClient((request) async {
      requests.add(request);
      return respond(request);
    }),
  );
  addTearDown(client.dispose);
  return (TeamService(client), requests);
}

Map<String, dynamic> _login({
  String id = 'm1',
  String role = 'bursar',
  String status = 'invited',
  String? code = 'K7M2QX9P',
  String? joinedAt,
  String? clerkUserId,
}) => {
  'id': id,
  'role': role,
  'status': status,
  'claim_code': code,
  'joined_at': joinedAt,
  'created_at': '2026-11-05T09:00:00Z',
  'clerk_user_id': clerkUserId,
};

Map<String, dynamic> _staff({
  String id = 's1',
  String firstName = 'Ada',
  String jobTitle = 'Bursar',
  Map<String, dynamic>? member,
}) => {
  'id': id,
  'first_name': firstName,
  'last_name': 'Okafor',
  'job_title': jobTitle,
  'phone': '+2348030000000',
  'email': 'ada@example.com',
  'photo_url': null,
  'staff_type': 'non_teaching',
  'status': 'active',
  'created_at': '2026-11-08T09:00:00Z',
  'member_id': member?['id'],
  'member': member,
};

void main() {
  test('reads staff with their login embedded through the member FK', () async {
    final (service, requests) = _service((request) {
      if (request.url.path.endsWith('/staff_private_details')) {
        return _json([
          {
            'staff_id': 's1',
            'address': '1 School Road',
            'residence_state': 'Lagos',
            'residence_lga': 'Ikeja',
          },
        ], request);
      }
      return _json([
        _staff(member: _login()),
        _staff(id: 's2', firstName: 'Chinedu', jobTitle: 'Teacher'),
      ], request);
    });

    final staff = await service.listStaff('kings');

    expect(requests, hasLength(2));
    final url = requests.first.url;
    expect(url.path, '/rest/v1/staff');
    expect(url.queryParameters['organization_id'], 'eq.kings');
    expect(
      url.queryParameters['select'],
      contains('member:organization_members!staff_member_fkey'),
    );

    expect(staff, hasLength(2));
    expect(staff.first.fullName, 'Ada Okafor');
    expect(staff.first.role, OrganizationMemberRole.bursar);
    expect(staff.first.access, StaffAccess.invitePending);
    expect(staff.first.login?.claimCode, 'K7M2QX9P');
    expect(staff.last.hasLogin, isFalse);
    expect(staff.last.access, StaffAccess.notOnApp);
    expect(staff.last.role, OrganizationMemberRole.teacher);
    expect(staff.first.privateDetails?.address, '1 School Road');
    expect(staff.first.privateDetails?.residenceState, 'Lagos');
    expect(staff.first.privateDetails?.residenceLga, 'Ikeja');
    expect(requests.last.url.path, '/rest/v1/staff_private_details');
  });

  test('adds a staff record through create_staff', () async {
    final (service, requests) = _service(
      (request) => _json(_staff(id: 'new'), request),
    );

    final staff = await service.createStaff(
      organizationId: 'kings',
      firstName: 'Ada',
      lastName: 'Okafor',
      phone: '+2348030000000',
      email: null,
      jobTitle: 'Bursar',
      staffType: 'non_teaching',
    );

    expect(staff.id, 'new');
    expect(requests.single.url.path, '/rest/v1/rpc/create_staff');
    expect(jsonDecode(requests.single.body), {
      'p_organization_id': 'kings',
      'p_first_name': 'Ada',
      'p_last_name': 'Okafor',
      'p_middle_name': null,
      'p_gender': null,
      'p_date_of_birth': null,
      'p_phone': '+2348030000000',
      'p_email': null,
      'p_job_title': 'Bursar',
      'p_staff_type': 'non_teaching',
      'p_address': null,
      'p_state_of_origin': null,
      'p_employment_date': null,
      'p_residence_state': null,
      'p_residence_lga': null,
    });
  });

  test(
    'update_staff sends every field, keeping the hidden ones intact',
    () async {
      final (service, requests) = _service(
        (request) => _json(_staff(id: 's1'), request),
      );
      final staff = StaffMember(
        id: 's1',
        firstName: 'Ada',
        lastName: 'Okafor',
        middleName: 'Chidi',
        gender: StaffGender.male,
        jobTitle: 'Bursar',
        phone: '+2348030000000',
        email: 'ada@example.com',
        photoId: 'photo-1',
        photoUrl: 'https://example.com/ada.jpg',
        staffNumber: 'KCL/STF/0001',
        staffType: 'non_teaching',
        status: StaffRecordStatus.active,
        createdAt: DateTime(2026, 11, 8),
      );
      final privateDetails = StaffPrivateDetails(
        dateOfBirth: DateTime(1990, 5, 1),
        address: '1 School Road',
        stateOfOrigin: 'Lagos',
        employmentDate: DateTime(2020, 9, 1),
      );

      final updated = await service.updateStaffDetails(
        staff: staff,
        privateDetails: privateDetails,
        changes: StaffDetailsChanges(
          firstName: 'Ada',
          middleName: 'Chidi',
          lastName: 'Okafor',
          gender: StaffGender.male,
          dateOfBirth: DateTime(1990, 5, 1),
          jobTitle: 'Teacher',
          staffType: 'teaching',
          status: StaffRecordStatus.onLeave,
          employmentDate: DateTime(2021, 1, 5),
          stateOfOrigin: 'Imo',
          phone: '+2348035550142',
          email: null,
          address: '9 New Road',
          residenceState: 'Lagos',
          residenceLga: 'Ikeja',
        ),
      );

      expect(updated.id, 's1');
      expect(requests.single.url.path, '/rest/v1/rpc/update_staff');
      expect(jsonDecode(requests.single.body), {
        'p_staff_id': 's1',
        'p_first_name': 'Ada',
        'p_last_name': 'Okafor',
        'p_middle_name': 'Chidi',
        'p_staff_number': 'KCL/STF/0001',
        'p_gender': 'male',
        'p_phone': '+2348035550142',
        'p_email': null,
        'p_photo_id': 'photo-1',
        'p_photo_url': 'https://example.com/ada.jpg',
        'p_job_title': 'Teacher',
        'p_staff_type': 'teaching',
        'p_status': 'on_leave',
        'p_date_of_birth': '1990-05-01',
        'p_address': '9 New Road',
        'p_state_of_origin': 'Imo',
        'p_employment_date': '2021-01-05',
        'p_residence_state': 'Lagos',
        'p_residence_lga': 'Ikeja',
      });
    },
  );

  test('a blocked details save says who can change them', () async {
    final (service, _) = _service(
      (request) => _refused('42501', request, 'permission denied'),
    );

    await expectLater(
      service.updateStaffDetails(
        staff: StaffMember(
          id: 's1',
          firstName: 'Ada',
          lastName: 'Okafor',
          staffType: 'teaching',
          status: StaffRecordStatus.active,
          createdAt: DateTime(2026, 11, 8),
        ),
        privateDetails: const StaffPrivateDetails(),
        changes: StaffDetailsChanges(
          firstName: 'Ada',
          lastName: 'Okafor',
          jobTitle: 'Teacher',
          staffType: 'teaching',
          status: StaffRecordStatus.active,
          phone: null,
          email: null,
        ),
      ),
      throwsA(
        isA<SupabaseRefusal>().having(
          (error) => error.message,
          'message',
          TeamService.detailsRefused,
        ),
      ),
    );
  });

  test('invite_staff returns the raw code, never the dashed form', () async {
    final (service, requests) = _service(
      (request) => _json('K7M2QX9P', request),
    );

    final code = await service.inviteStaff(
      staffId: 's1',
      role: OrganizationMemberRole.teacher,
    );

    expect(code, 'K7M2QX9P');
    expect(requests.single.url.path, '/rest/v1/rpc/invite_staff');
    expect(jsonDecode(requests.single.body), {
      'p_staff_id': 's1',
      'p_role': 'teacher',
    });
  });

  test(
    'cancelling an invite deletes the membership and asks for its id',
    () async {
      final (service, requests) = _service(
        (request) => _json([
          {'id': 'm1'},
        ], request),
      );

      await service.cancelInvite('m1');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/rest/v1/organization_members');
      expect(requests.single.url.queryParameters['id'], 'eq.m1');
    },
  );

  test('a cancel row-level security blocks touches nothing', () async {
    final (service, _) = _service((request) => _json([], request));

    await expectLater(
      service.cancelInvite('m1'),
      throwsA(
        isA<SupabaseRefusal>().having(
          (error) => error.message,
          'message',
          TeamService.ownersOnly,
        ),
      ),
    );
  });

  test('a role someone already has asks for a different one', () async {
    final (service, _) = _service(
      (request) => _refused('23505', request, 'duplicate key'),
    );

    await expectLater(
      service.changeRole(memberId: 'm1', role: OrganizationMemberRole.admin),
      throwsA(
        isA<SupabaseRefusal>().having(
          (error) => error.message,
          'message',
          contains('already have that role'),
        ),
      ),
    );
  });

  test(
    "removing an active owner's record keeps the database's message",
    () async {
      final (service, _) = _service(
        (request) => _refused(
          'P0001',
          request,
          "This is an owner's staff record. Make someone else the owner, or "
              'suspend this owner, before removing it.',
        ),
      );

      await expectLater(
        service.removeStaff('s1'),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            contains("This is an owner's staff record"),
          ),
        ),
      );
    },
  );
}
