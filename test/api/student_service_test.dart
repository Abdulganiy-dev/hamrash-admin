import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
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
}
