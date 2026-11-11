import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_details_changes.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart'
    show FilterPick;
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
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
  group('listStaffPage', () {
    Map<String, dynamic> page({String? cursor = 'abc', int total = 31}) => {
      'rows': [
        _staff(member: _login()),
        _staff(id: 's2', firstName: 'Chinedu', jobTitle: 'Teacher'),
      ],
      'next_cursor': cursor,
      'total': total,
      'counts': {
        'all': 40,
        'on_app': 30,
        'code_ready': 4,
        'not_on_app': 5,
        'suspended': 1,
      },
    };

    test('sends the filter to list_staff as its parameters', () async {
      final (service, requests) = _service((request) => _json(page(), request));

      await service.listStaffPage(
        organizationId: 'kings',
        filter: const StaffFilter(
          search: '  ada ',
          login: StaffLoginFilter.codeReady,
          roles: {OrganizationMemberRole.teacher, OrganizationMemberRole.admin},
          staffType: StaffTypeFilter.teaching,
          statuses: {StaffRecordStatus.active, StaffRecordStatus.onLeave},
          sort: StaffSort.newest,
        ),
        cursor: 'next',
      );

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/rest/v1/rpc/list_staff');
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['p_organization_id'], 'kings');
      expect(body['p_search'], 'ada');
      expect(body['p_login'], 'code_ready');
      expect(body['p_roles'], unorderedEquals(['teacher', 'admin']));
      expect(body['p_staff_type'], 'teaching');
      expect(body['p_statuses'], unorderedEquals(['active', 'on_leave']));
      expect(body['p_sort'], 'newest');
      expect(body['p_limit'], 30);
      expect(body['p_cursor'], 'next');
    });

    test('the default filter asks for active staff by name, page 1', () async {
      final (service, requests) = _service((request) => _json(page(), request));

      await service.listStaffPage(organizationId: 'kings', limit: 1);

      final body = jsonDecode(requests.single.body) as Map;
      expect(body['p_search'], isNull);
      expect(body['p_login'], 'all');
      expect(body['p_roles'], isNull);
      expect(body['p_staff_type'], isNull);
      expect(body['p_statuses'], ['active']);
      expect(body['p_sort'], 'name');
      expect(body['p_limit'], 1);
      expect(body['p_cursor'], isNull);
    });

    test('reads the rows, cursor, total and counts', () async {
      final (service, _) = _service((request) => _json(page(), request));

      final result = await service.listStaffPage(organizationId: 'kings');

      expect(result.rows, hasLength(2));
      expect(result.rows.first.fullName, 'Ada Okafor');
      expect(result.rows.first.role, OrganizationMemberRole.bursar);
      expect(result.rows.first.access, StaffAccess.invitePending);
      expect(result.rows.first.login?.claimCode, 'K7M2QX9P');
      expect(result.rows.last.hasLogin, isFalse);
      expect(result.rows.last.privateDetails, isNull);
      expect(result.nextCursor, 'abc');
      expect(result.total, 31);
      expect(result.counts.all, 40);
      expect(result.counts.onApp, 30);
      expect(result.counts.codeReady, 4);
      expect(result.counts.notOnApp, 5);
      expect(result.counts.suspended, 1);
    });

    test('the last page has no cursor', () async {
      final (service, _) = _service(
        (request) => _json(page(cursor: null, total: 2), request),
      );

      final result = await service.listStaffPage(organizationId: 'kings');

      expect(result.nextCursor, isNull);
    });

    test('a refusal (22023) reads as its own message', () async {
      final (service, _) = _service(
        (request) => _refused(
          '22023',
          request,
          'This page cursor is not valid for this list. Load the list again '
              'from the start',
        ),
      );

      await expectLater(
        service.listStaffPage(organizationId: 'kings', cursor: 'stale'),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            startsWith('This page cursor is not valid'),
          ),
        ),
      );
    });
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

  group('several roles', () {
    Map<String, dynamic> membership(String id, String role, String created) =>
        _login(
          id: id,
          role: role,
          status: 'active',
          code: null,
          joinedAt: '2026-09-03T09:00:00Z',
          clerkUserId: 'user-ngozi',
        )..['created_at'] = created;

    test('a staff list page reads every role each person holds', () async {
      final (service, requests) = _service((request) {
        if (request.url.path == '/rest/v1/rpc/list_staff') {
          return _json({
            'rows': [
              _staff(
                firstName: 'Ngozi',
                jobTitle: 'Teacher',
                member: membership('m-admin', 'admin', '2026-09-03T09:00:00Z'),
              ),
              _staff(id: 's2', firstName: 'Chinedu', jobTitle: 'Teacher'),
            ],
            'next_cursor': null,
            'total': 2,
            'counts': {
              'all': 2,
              'on_app': 1,
              'code_ready': 0,
              'not_on_app': 1,
              'suspended': 0,
            },
          }, request);
        }
        // The later teacher row comes back first: the login stays first
        // anyway, the rest follow in the order they were added.
        return _json([
          membership('m-bursar', 'bursar', '2026-11-01T09:00:00Z'),
          membership('m-teacher', 'teacher', '2026-10-01T09:00:00Z'),
          membership('m-admin', 'admin', '2026-09-03T09:00:00Z'),
        ], request);
      });

      final page = await service.listStaffPage(organizationId: 'kings');

      expect(page.rows.first.roles, [
        OrganizationMemberRole.admin,
        OrganizationMemberRole.teacher,
        OrganizationMemberRole.bursar,
      ]);
      expect(page.rows.last.roles, [OrganizationMemberRole.teacher]);
      final read = requests.last;
      expect(read.url.path, '/rest/v1/organization_members');
      expect(read.url.queryParameters['organization_id'], 'eq.kings');
      expect(read.url.queryParameters['clerk_user_id'], 'in.("user-ngozi")');
    });

    test('a failed roles read leaves the page with its one login', () async {
      final (service, _) = _service((request) {
        if (request.url.path == '/rest/v1/rpc/list_staff') {
          return _json({
            'rows': [
              _staff(
                member: membership('m-admin', 'admin', '2026-09-03T09:00:00Z'),
              ),
            ],
            'next_cursor': null,
            'total': 1,
            'counts': {'all': 1},
          }, request);
        }
        return _refused('XX000', request, 'boom');
      });

      final page = await service.listStaffPage(organizationId: 'kings');

      expect(page.rows.single.roles, [OrganizationMemberRole.admin]);
    });

    test(
      'add_member_role sends the member and role, returns the row',
      () async {
        final (service, requests) = _service(
          (request) => _json({
            ..._login(
              id: 'm-new',
              role: 'bursar',
              status: 'active',
              code: null,
              clerkUserId: 'user-ngozi',
            ),
            'organization_id': 'kings',
          }, request),
        );

        final added = await service.addMemberRole(
          memberId: 'm-admin',
          role: OrganizationMemberRole.bursar,
        );

        expect(requests.single.url.path, '/rest/v1/rpc/add_member_role');
        final body = jsonDecode(requests.single.body) as Map;
        expect(body, {'p_member_id': 'm-admin', 'p_role': 'bursar'});
        expect(added.id, 'm-new');
        expect(added.role, OrganizationMemberRole.bursar);
        expect(added.status, OrganizationMemberStatus.active);
      },
    );

    test('add_member_role refusals read as the database wrote them', () async {
      final (service, _) = _service(
        (request) => _refused(
          'P0001',
          request,
          'They already have the bursar role at this school',
        ),
      );

      await expectLater(
        service.addMemberRole(
          memberId: 'm-admin',
          role: OrganizationMemberRole.bursar,
        ),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            'They already have the bursar role at this school',
          ),
        ),
      );
    });

    test('a role the caller may not add says who can', () async {
      final (service, _) = _service(
        (request) => _refused('42501', request, 'not allowed'),
      );

      await expectLater(
        service.addMemberRole(
          memberId: 'm-admin',
          role: OrganizationMemberRole.admin,
        ),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            TeamService.addRoleRefused,
          ),
        ),
      );
    });

    test('suspending changes all of the memberships in one request', () async {
      final (service, requests) = _service(
        (request) => _json([
          {'id': 'm-admin'},
          {'id': 'm-teacher'},
        ], request),
      );

      await service.setSuspended(
        memberIds: ['m-admin', 'm-teacher'],
        suspended: true,
      );

      expect(requests.single.method, 'PATCH');
      expect(
        requests.single.url.queryParameters['id'],
        'in.("m-admin","m-teacher")',
      );
      expect(jsonDecode(requests.single.body), {'status': 'suspended'});
    });
  });

  group('teaching filter', () {
    test('sends the subject and class to list_staff', () async {
      final (service, requests) = _service(
        (request) => _json({
          'rows': <Object>[],
          'next_cursor': null,
          'total': 0,
          'counts': {'all': 0},
        }, request),
      );

      await service.listStaffPage(
        organizationId: 'kings',
        filter: const StaffFilter(
          subject: FilterPick('maths', 'Mathematics'),
          schoolClass: FilterPick('jss2', 'JSS 2'),
        ),
      );

      final body = jsonDecode(requests.single.body) as Map;
      expect(body['p_subject_id'], 'maths');
      expect(body['p_class_id'], 'jss2');
    });

    test('no teaching filter sends nulls', () async {
      final (service, requests) = _service(
        (request) => _json({
          'rows': <Object>[],
          'next_cursor': null,
          'total': 0,
          'counts': {'all': 0},
        }, request),
      );

      await service.listStaffPage(organizationId: 'kings');

      final body = jsonDecode(requests.single.body) as Map;
      expect(body['p_subject_id'], isNull);
      expect(body['p_class_id'], isNull);
    });

    test(
      'reads each teacher with the classes where they teach the subject',
      () async {
        Map<String, dynamic> assignment(String arm, String cls) => {
          'subject_id': 'maths',
          'subject_name': 'Mathematics',
          'arm_id': 'arm-$cls$arm',
          'arm_name': arm,
          'class_id': 'c-$cls',
          'class_name': cls,
        };
        final (service, _) = _service(
          (request) => _json({
            'rows': [
              {
                ..._staff(firstName: 'John'),
                'teaching': [
                  assignment('A', 'JSS 1'),
                  assignment('A', 'JSS 2'),
                ],
              },
              {
                ..._staff(id: 's2', firstName: 'Jane'),
                'teaching': [assignment('B', 'SSS 1')],
              },
              _staff(id: 's3', firstName: 'Plain'),
            ],
            'next_cursor': null,
            'total': 3,
            'counts': {'all': 3},
          }, request),
        );

        final page = await service.listStaffPage(
          organizationId: 'kings',
          filter: const StaffFilter(
            subject: FilterPick('maths', 'Mathematics'),
          ),
        );

        expect(page.rows[0].teaching?.map((t) => t.armLabel), [
          'JSS 1A',
          'JSS 2A',
        ]);
        expect(page.rows[1].teaching?.single.armLabel, 'SSS 1B');
        expect(page.rows[2].teaching, isNull);
      },
    );
  });
}
