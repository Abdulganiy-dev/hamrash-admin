import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_profile.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_details_changes.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
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

(StudentService, List<http.Request>) _service(
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
  return (StudentService(client), requests);
}

Map<String, dynamic> _row(
  String id,
  String first, {
  Map<String, dynamic>? arm,
  Map<String, dynamic>? subject,
}) => {
  'id': id,
  'first_name': first,
  'middle_name': null,
  'last_name': 'Okafor',
  'admission_number': 'KCL/2026/$id',
  'photo_url': null,
  'status': 'active',
  'arm': arm,
  'subject': subject,
};

Map<String, dynamic> _arm(String name, String className, int order) => {
  'id': 'arm-$className$name',
  'name': name,
  'class_id': 'c-$className',
  'class_name': className,
  'section_id': 'sec',
  'class_sort_order': order,
};

Map<String, dynamic> _maths({Map<String, dynamic>? teacher}) => {
  'id': 'maths',
  'name': 'Mathematics',
  'is_compulsory': true,
  'teacher': teacher,
};

void main() {
  group('listStudentsPage', () {
    test(
      'the default filter asks for active students in class order',
      () async {
        final (service, requests) = _service(
          (request) => _json({
            'rows': <Object>[],
            'next_cursor': null,
            'total': 0,
            'groups': <Object>[],
          }, request),
        );

        await service.listStudentsPage(organizationId: 'kings');

        expect(requests.single.url.path, '/rest/v1/rpc/list_students');
        final body = jsonDecode(requests.single.body) as Map;
        expect(body['p_organization_id'], 'kings');
        expect(body['p_search'], isNull);
        expect(body['p_class_id'], isNull);
        expect(body['p_arm_id'], isNull);
        expect(body['p_subject_id'], isNull);
        expect(body['p_statuses'], ['active']);
        expect(body['p_sort'], 'class');
        expect(body['p_limit'], 30);
        expect(body['p_cursor'], isNull);
      },
    );

    test('sends every filter, the page size and the cursor', () async {
      final (service, requests) = _service(
        (request) => _json({
          'rows': <Object>[],
          'next_cursor': null,
          'total': 0,
          'groups': <Object>[],
        }, request),
      );

      await service.listStudentsPage(
        organizationId: 'kings',
        filter: const StudentFilter(
          search: '  ada ',
          schoolClass: FilterPick('c1', 'JSS 1'),
          arm: FilterPick('a1', 'A'),
          subject: FilterPick('maths', 'Mathematics'),
          statuses: {StudentStatusFilter.graduated, StudentStatusFilter.active},
          sort: StudentSort.name,
        ),
        limit: 10,
        cursor: 'next',
      );

      final body = jsonDecode(requests.single.body) as Map;
      expect(body['p_search'], 'ada');
      expect(body['p_class_id'], 'c1');
      expect(body['p_arm_id'], 'a1');
      expect(body['p_subject_id'], 'maths');
      expect(body['p_statuses'], unorderedEquals(['active', 'graduated']));
      expect(body['p_sort'], 'name');
      expect(body['p_limit'], 10);
      expect(body['p_cursor'], 'next');
    });

    test('reads rows, cursor, total and the arm counts', () async {
      final (service, _) = _service(
        (request) => _json({
          'rows': [
            _row('1', 'Ada', arm: _arm('A', 'JSS 1', 4)),
            _row('2', 'Gina'),
          ],
          'next_cursor': 'abc',
          'total': 31,
          'groups': [
            {'arm_id': 'arm-JSS 1A', 'count': 20},
            {'arm_id': null, 'count': 11},
          ],
        }, request),
      );

      final page = await service.listStudentsPage(organizationId: 'kings');

      expect(page.rows, hasLength(2));
      expect(page.rows.first.armLabel, 'JSS 1A');
      expect(page.rows.last.armId, isNull);
      expect(page.nextCursor, 'abc');
      expect(page.total, 31);
      expect(page.groupCounts, {'arm-JSS 1A': 20, '': 11});
    });

    test(
      'a subject filter returns each student with their class teacher',
      () async {
        final (service, _) = _service(
          (request) => _json({
            'rows': [
              _row(
                '1',
                'Student A',
                arm: _arm('A', 'JSS 2', 5),
                subject: _maths(
                  teacher: {
                    'id': 't1',
                    'first_name': 'John',
                    'last_name': 'Bello',
                  },
                ),
              ),
              _row(
                '2',
                'Student C',
                arm: _arm('A', 'SSS 1', 7),
                subject: _maths(
                  teacher: {
                    'id': 't2',
                    'first_name': 'Jane',
                    'last_name': 'Cole',
                  },
                ),
              ),
              _row(
                '3',
                'Student E',
                arm: _arm('B', 'SSS 1', 7),
                subject: _maths(),
              ),
            ],
            'next_cursor': null,
            'total': 3,
            'groups': <Object>[],
          }, request),
        );

        final page = await service.listStudentsPage(
          organizationId: 'kings',
          filter: const StudentFilter(
            subject: FilterPick('maths', 'Mathematics'),
          ),
        );

        expect(
          [for (final s in page.rows) s.subject?.teacherName],
          ['John Bello', 'Jane Cole', ''],
        );
        // A subject nobody teaches in that arm is handled, not an error.
        expect(page.rows.last.subject?.hasTeacher, isFalse);
        expect(page.rows.last.armLabel, 'SSS 1B');
      },
    );

    test('a stale cursor (22023) reads as its own message', () async {
      final (service, _) = _service(
        (request) => _json(
          {
            'code': '22023',
            'message':
                'This page cursor is not valid for this list. Load the '
                'list again from the start',
            'details': null,
            'hint': null,
          },
          request,
          status: 400,
        ),
      );

      await expectLater(
        service.listStudentsPage(organizationId: 'kings', cursor: 'stale'),
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

  group('one student', () {
    http.Response student(http.Request request) {
      switch (request.url.path) {
        case '/rest/v1/students':
          return _json({
            'id': 'st1',
            'first_name': 'Abdullahi',
            'middle_name': null,
            'last_name': 'Yusuf',
            'admission_number': 'KCL/2026/0021',
            'gender': 'male',
            'admission_date': '2026-09-08',
            'photo_id': null,
            'photo_url': null,
            'status': 'active',
            'created_at': '2026-09-08T09:00:00Z',
            'updated_at': '2026-11-10T09:00:00Z',
            'member_id': 'm1',
            'member': {
              'id': 'm1',
              'status': 'invited',
              'claim_code': 'R4TB8KXW',
              'joined_at': null,
              'created_at': '2026-11-08T09:00:00Z',
            },
            'details': {
              'date_of_birth': '2014-03-02',
              'address': '22 Ahmadu Bello Way',
              'state_of_origin': 'Kano',
              'lga': 'Nassarawa',
              'blood_group': 'O+',
              'genotype': 'AA',
              'medical_notes': null,
            },
          }, request);
        case '/rest/v1/student_parents':
          return _json([
            {
              'relationship': 'father',
              'is_primary_contact': false,
              'parents': {
                'id': 'p2',
                'title': 'Mr',
                'first_name': 'Musa',
                'last_name': 'Yusuf',
                'phone': '+2348031124455',
                'photo_url': null,
                'details': {'email': null},
              },
            },
            {
              'relationship': 'mother',
              'is_primary_contact': true,
              'parents': {
                'id': 'p1',
                'title': 'Mrs',
                'first_name': 'Halima',
                'last_name': 'Yusuf',
                'phone': '+2348034451290',
                'photo_url': null,
                'details': [
                  {'email': 'halima@example.com'},
                ],
              },
            },
          ], request);
        case '/rest/v1/academic_sessions':
          return _json({'id': 'sess', 'name': '2026/27'}, request);
        case '/rest/v1/student_placements':
          return _json({
            'arm_id': 'arm-1b',
            'class_arms': {
              'id': 'arm-1b',
              'name': 'B',
              'class_id': 'jss1',
              'classes': {'id': 'jss1', 'name': 'JSS 1'},
            },
          }, request);
        case '/rest/v1/arm_subjects':
          return _json([
            {
              'subject_id': 'french',
              'is_compulsory': false,
              'subjects': {'name': 'French', 'code': 'FRN', 'sort_order': 2},
            },
            {
              'subject_id': 'maths',
              'is_compulsory': true,
              'subjects': {
                'name': 'Mathematics',
                'code': 'MTH',
                'sort_order': 1,
              },
            },
          ], request);
        case '/rest/v1/student_subjects':
          return _json([
            {'subject_id': 'french'},
          ], request);
        case '/rest/v1/class_teachers':
          return _json([
            {
              'is_lead': false,
              'staff': {'first_name': 'Assistant', 'last_name': 'Teacher'},
            },
            {
              'is_lead': true,
              'staff': {'first_name': 'Ibrahim', 'last_name': 'Bello'},
            },
          ], request);
      }
      return _json({}, request, status: 404);
    }

    test('reads the record, login, parents, class and subjects', () async {
      final (service, requests) = _service(student);

      final profile = await service.getStudent(
        organizationId: 'kings',
        studentId: 'st1',
      );

      expect(profile.fullName, 'Abdullahi Yusuf');
      expect(profile.gender, StudentGender.male);
      expect(profile.access, StudentAccess.codeReady);
      expect(profile.login?.claimCode, 'R4TB8KXW');
      expect(profile.details.stateOfOrigin, 'Kano');
      expect(profile.updatedAt, isNotNull);
      // The primary contact first, then the rest by name.
      expect(profile.parents.map((p) => p.id), ['p1', 'p2']);
      expect(profile.parents.first.email, 'halima@example.com');
      expect(profile.parents.last.email, isNull);
      final placement = profile.placement!;
      expect(placement.armLabel, 'JSS 1B');
      expect(placement.sessionName, '2026/27');
      expect(placement.leadTeacher, 'Ibrahim Bello');
      expect(placement.offers.map((o) => o.name), ['Mathematics', 'French']);
      expect(placement.chosen.map((o) => o.name), ['French']);
      expect(placement.core.length, 1);
      expect(
        requests.where((r) => r.url.path == '/rest/v1/students'),
        hasLength(1),
      );
    });

    test(
      'moving calls move_student_to_arm and returns the dropped count',
      () async {
        final (service, requests) = _service((request) => _json(2, request));

        final dropped = await service.moveToArm(
          studentId: 'st1',
          armId: 'arm-1a',
        );

        expect(requests.single.url.path, '/rest/v1/rpc/move_student_to_arm');
        expect(jsonDecode(requests.single.body), {
          'p_student_id': 'st1',
          'p_arm_id': 'arm-1a',
        });
        expect(dropped, 2);
      },
    );

    test('a refused move reads as the database wrote it', () async {
      final (service, _) = _service(
        (request) => _json(
          {
            'code': 'P0001',
            'message': 'They are already in that arm',
            'details': null,
            'hint': null,
          },
          request,
          status: 400,
        ),
      );

      await expectLater(
        service.moveToArm(studentId: 'st1', armId: 'arm-1a'),
        throwsA(
          isA<SupabaseRefusal>().having(
            (e) => e.message,
            'message',
            'They are already in that arm',
          ),
        ),
      );
    });

    test(
      'a status change sends the whole record through update_student',
      () async {
        final (service, requests) = _service((request) {
          if (request.url.path == '/rest/v1/rpc/update_student') {
            return _json({'id': 'st1'}, request);
          }
          return student(request);
        });
        final profile = await service.getStudent(
          organizationId: 'kings',
          studentId: 'st1',
        );
        requests.clear();

        await service.setStudentStatus(
          student: profile,
          status: StudentStatusFilter.withdrawn,
        );

        final body = jsonDecode(requests.single.body) as Map;
        expect(requests.single.url.path, '/rest/v1/rpc/update_student');
        expect(body['p_student_id'], 'st1');
        expect(body['p_status'], 'withdrawn');
        expect(body['p_first_name'], 'Abdullahi');
        expect(body['p_admission_number'], 'KCL/2026/0021');
        expect(body['p_admission_date'], '2026-09-08');
        expect(body['p_date_of_birth'], '2014-03-02');
        expect(body['p_blood_group'], 'O+');
      },
    );

    test(
      'saving details sends the changed fields and the rest unchanged',
      () async {
        final (service, requests) = _service((request) {
          if (request.url.path == '/rest/v1/rpc/update_student') {
            return _json({'id': 'st1'}, request);
          }
          return student(request);
        });
        final profile = await service.getStudent(
          organizationId: 'kings',
          studentId: 'st1',
        );
        requests.clear();

        await service.updateStudentDetails(
          student: profile,
          changes: StudentDetailsChanges(
            firstName: 'Abdullah',
            lastName: 'Yusuf',
            gender: StudentGender.male,
            dateOfBirth: DateTime(2014, 3, 3),
            stateOfOrigin: 'Kano',
            bloodGroup: 'A+',
          ),
        );

        final body = jsonDecode(requests.single.body) as Map;
        expect(body['p_first_name'], 'Abdullah');
        expect(body['p_date_of_birth'], '2014-03-03');
        expect(body['p_blood_group'], 'A+');
        expect(body['p_status'], 'active');
        expect(body['p_address'], isNull);
      },
    );

    test(
      'optional subjects: adds the new ones, then removes the rest',
      () async {
        final (service, requests) = _service((request) {
          if (request.method == 'DELETE') {
            return _json([
              {'subject_id': 'agric'},
            ], request);
          }
          return _json({}, request, status: 201);
        });

        await service.setOptionalSubjects(
          organizationId: 'kings',
          studentId: 'st1',
          sessionId: 'sess',
          current: {'agric', 'french'},
          subjectIds: {'french', 'music'},
        );

        expect(requests.map((r) => r.method), ['POST', 'DELETE']);
        final added = jsonDecode(requests.first.body) as List;
        expect(added.single['subject_id'], 'music');
        expect(requests.last.url.queryParameters['subject_id'], 'in.("agric")');
      },
    );

    test('inviting calls invite_student and returns the raw code', () async {
      final (service, requests) = _service(
        (request) => _json('R4TB8KXW', request),
      );

      final code = await service.inviteStudent('st1');

      expect(requests.single.url.path, '/rest/v1/rpc/invite_student');
      expect(code, 'R4TB8KXW');
    });

    test(
      'suspending changes the login row; an empty result is a refusal',
      () async {
        final (service, requests) = _service(
          (request) => _json([
            {'id': 'm1'},
          ], request),
        );
        await service.setSuspended(memberId: 'm1', suspended: true);
        expect(jsonDecode(requests.single.body), {'status': 'suspended'});

        final (blocked, _) = _service((request) => _json([], request));
        await expectLater(
          blocked.setSuspended(memberId: 'm1', suspended: false),
          throwsA(isA<SupabaseRefusal>()),
        );
        await expectLater(
          blocked.removeStudent('st1'),
          throwsA(isA<SupabaseRefusal>()),
        );
        await expectLater(
          blocked.cancelInvite('m1'),
          throwsA(isA<SupabaseRefusal>()),
        );
      },
    );

    test('removing deletes the student row', () async {
      final (service, requests) = _service(
        (request) => _json([
          {'id': 'st1'},
        ], request),
      );

      await service.removeStudent('st1');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/rest/v1/students');
      expect(requests.single.url.queryParameters['id'], 'eq.st1');
    });

    test('linking a parent writes the student_parents row', () async {
      final (service, requests) = _service(
        (request) => _json({}, request, status: 201),
      );

      await service.linkParent(
        organizationId: 'kings',
        studentId: 'st1',
        parentId: 'p7',
        relationship: ParentRelationship.father,
        primary: false,
      );

      expect(requests.single.url.path, '/rest/v1/student_parents');
      expect(jsonDecode(requests.single.body), {
        'organization_id': 'kings',
        'student_id': 'st1',
        'parent_id': 'p7',
        'relationship': 'father',
        'is_primary_contact': false,
      });
    });

    test('a parent already linked says so', () async {
      final (service, _) = _service(
        (request) => _json(
          {
            'code': '23505',
            'message': 'duplicate key',
            'details': null,
            'hint': null,
          },
          request,
          status: 409,
        ),
      );

      await expectLater(
        service.linkParent(
          organizationId: 'kings',
          studentId: 'st1',
          parentId: 'p7',
          relationship: ParentRelationship.father,
          primary: false,
        ),
        throwsA(
          isA<SupabaseRefusal>().having(
            (e) => e.message,
            'message',
            'They are already linked to this student.',
          ),
        ),
      );
    });

    test('a new parent goes through create_parent, then is linked', () async {
      final (service, requests) = _service((request) {
        if (request.url.path == '/rest/v1/rpc/create_parent') {
          return _json({'id': 'new-parent'}, request);
        }
        return _json({}, request, status: 201);
      });

      final id = await service.createAndLinkParent(
        organizationId: 'kings',
        studentId: 'st1',
        title: 'Mr',
        firstName: 'Sani',
        lastName: 'Danladi',
        phone: '+2348052209134',
        email: 'sani@example.com',
        occupation: 'Engineer',
        address: '1 Road',
        relationship: ParentRelationship.father,
        primary: true,
      );

      expect(id, 'new-parent');
      expect(requests.map((r) => r.url.path), [
        '/rest/v1/rpc/create_parent',
        '/rest/v1/student_parents',
      ]);
      final created = jsonDecode(requests.first.body) as Map;
      expect(created['p_email'], 'sani@example.com');
      expect(created['p_phone'], '+2348052209134');
      final link = jsonDecode(requests.last.body) as Map;
      expect(link['parent_id'], 'new-parent');
      expect(link['is_primary_contact'], isTrue);
    });

    test('unlinking can hand the primary contact to another parent', () async {
      final (service, requests) = _service(
        (request) => _json([
          {'parent_id': 'p1'},
        ], request),
      );

      await service.unlinkParent(
        studentId: 'st1',
        parentId: 'p1',
        newPrimaryId: 'p2',
      );

      expect(requests.map((r) => r.method), ['DELETE', 'PATCH']);
      expect(jsonDecode(requests.last.body), {'is_primary_contact': true});
      expect(requests.last.url.queryParameters['parent_id'], 'eq.p2');
    });

    test(
      'the move sheet\'s arms come with headcount and lead teacher',
      () async {
        final (service, requests) = _service(
          (request) => _json([
            {
              'id': 'arm-1b',
              'name': 'B',
              'is_active': true,
              'student_placements': [
                {'count': 30},
              ],
              'class_teachers': [
                {
                  'is_lead': true,
                  'staff': {'first_name': 'Ibrahim', 'last_name': 'Bello'},
                },
              ],
            },
            {
              'id': 'arm-1a',
              'name': 'A',
              'is_active': true,
              'student_placements': [],
              'class_teachers': [],
            },
          ], request),
        );

        final arms = await service.listArmChoices(
          organizationId: 'kings',
          classId: 'jss1',
          className: 'JSS 1',
          sessionId: 'sess',
        );

        expect(arms.map((a) => a.label), ['JSS 1A', 'JSS 1B']);
        expect(arms.first.caption, '0 students · No lead yet');
        expect(arms.last.caption, '30 students · Lead Ibrahim Bello');
        expect(
          requests.single.url.queryParameters['student_placements.session_id'],
          'eq.sess',
        );
      },
    );

    test('the login statuses map to the Access card', () {
      expect(OrganizationMemberStatus.invited.value, 'invited');
    });
  });

  group('one parent', () {
    http.Response parent(http.Request request) {
      switch (request.url.path) {
        case '/rest/v1/parents':
          return _json({
            'id': 'p1',
            'title': 'Mrs',
            'first_name': 'Halima',
            'last_name': 'Yusuf',
            'phone': '+2348034451290',
            'alt_phone': null,
            'photo_id': null,
            'photo_url': null,
            'is_active': true,
            'member_id': null,
            'member': null,
            'details': {
              'email': 'halima.y@gmail.com',
              'occupation': 'Pharmacist',
              'address': '22 Ahmadu Bello Way',
            },
          }, request);
        case '/rest/v1/student_parents':
          return _json([
            {
              'relationship': 'mother',
              'is_primary_contact': false,
              'students': {
                'id': 'st2',
                'first_name': 'Aisha',
                'last_name': 'Yusuf',
                'photo_url': null,
                'student_placements': [
                  {
                    'session_id': 'old',
                    'class_arms': {
                      'name': 'A',
                      'classes': {'name': 'Primary 3'},
                    },
                  },
                  {
                    'session_id': 'sess',
                    'class_arms': {
                      'name': 'A',
                      'classes': {'name': 'Primary 4'},
                    },
                  },
                ],
              },
            },
            {
              'relationship': 'mother',
              'is_primary_contact': true,
              'students': {
                'id': 'st1',
                'first_name': 'Abdullahi',
                'last_name': 'Yusuf',
                'photo_url': null,
                'student_placements': [],
              },
            },
          ], request);
        case '/rest/v1/academic_sessions':
          return _json({'id': 'sess'}, request);
      }
      return _json({}, request, status: 404);
    }

    test('reads the parent, their details and their children', () async {
      final (service, _) = _service(parent);

      final profile = await service.getParent(
        organizationId: 'kings',
        parentId: 'p1',
      );

      expect(profile.displayName, 'Mrs Halima Yusuf');
      expect(profile.email, 'halima.y@gmail.com');
      expect(profile.occupation, 'Pharmacist');
      expect(profile.login, isNull);
      // The primary contact first; the arm is the current session's.
      expect(profile.children.map((c) => c.firstName), ['Abdullahi', 'Aisha']);
      expect(profile.children.first.armLabel, isNull);
      expect(profile.children.first.caption, 'Primary contact');
      expect(profile.children.last.armLabel, 'Primary 4A');
      expect(profile.children.last.caption, 'Primary 4A');
    });

    test(
      'saving details sends the whole record through update_parent',
      () async {
        final (service, requests) = _service((request) {
          if (request.url.path == '/rest/v1/rpc/update_parent') {
            return _json({'id': 'p1'}, request);
          }
          return parent(request);
        });
        final profile = await service.getParent(
          organizationId: 'kings',
          parentId: 'p1',
        );
        requests.clear();

        await service.updateParentDetails(
          parent: profile,
          changes: const ParentDetailsChanges(
            title: 'Mrs',
            firstName: 'Halima',
            lastName: 'Yusuf',
            phone: '+2348034451290',
            email: 'halima.y@gmail.com',
            occupation: 'Doctor',
            address: '22 Ahmadu Bello Way',
          ),
        );

        final body = jsonDecode(requests.single.body) as Map;
        expect(requests.single.url.path, '/rest/v1/rpc/update_parent');
        expect(body['p_parent_id'], 'p1');
        expect(body['p_occupation'], 'Doctor');
        expect(body['p_is_active'], isTrue);
        expect(body['p_phone'], '+2348034451290');
      },
    );

    test('inviting calls invite_parent', () async {
      final (service, requests) = _service(
        (request) => _json('R4TB8KXW', request),
      );

      expect(await service.inviteParent('p1'), 'R4TB8KXW');
      expect(requests.single.url.path, '/rest/v1/rpc/invite_parent');
    });

    test('removing deletes the parent; nothing removed is a refusal', () async {
      final (service, requests) = _service(
        (request) => _json([
          {'id': 'p1'},
        ], request),
      );
      await service.removeParent('p1');
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/rest/v1/parents');

      final (blocked, _) = _service((request) => _json([], request));
      await expectLater(
        blocked.removeParent('p1'),
        throwsA(isA<SupabaseRefusal>()),
      );
    });

    test('a new parent keeps the photo the sheet uploaded', () async {
      final (service, requests) = _service((request) {
        if (request.url.path == '/rest/v1/rpc/create_parent') {
          return _json({'id': 'new-parent'}, request);
        }
        return _json({}, request, status: 201);
      });

      await service.createAndLinkParent(
        organizationId: 'kings',
        studentId: 'st1',
        title: 'Mr',
        firstName: 'Sani',
        lastName: 'Danladi',
        phone: '+2348052209134',
        email: 'sani@example.com',
        occupation: 'Engineer',
        address: '1 Road',
        relationship: ParentRelationship.father,
        primary: false,
        photoId: 'img1',
        photoUrl: 'https://x/img1',
      );

      final created = jsonDecode(requests.first.body) as Map;
      expect(created['p_photo_id'], 'img1');
      expect(created['p_photo_url'], 'https://x/img1');
    });
  });
}
