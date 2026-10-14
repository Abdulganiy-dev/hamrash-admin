import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
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

http.Response _refused(String code, http.Request request) => _json(
  {'code': code, 'message': 'refused', 'details': null, 'hint': null},
  request,
  status: 409,
);

/// A service whose database answers every request with [respond].
(ClassStructureService, List<http.Request>) _service(
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
  return (ClassStructureService(client), requests);
}

ClassArm _arm(String id, String name, int minute) => ClassArm(
  id: id,
  classId: 'p1',
  name: name,
  isActive: true,
  createdAt: DateTime.utc(2026, 10, 14, 9, minute),
);

final _primary1 = SchoolClass(
  id: 'p1',
  sectionId: 'primary',
  name: 'Primary 1',
  sortOrder: 1,
  isGraduating: false,
  isActive: true,
  arms: [_arm('a', 'A', 0), _arm('b', 'B', 1)],
);

final _primary = SchoolSection(
  id: 'primary',
  name: 'Primary',
  sortOrder: 2,
  isActive: true,
  classes: [_primary1],
);

void main() {
  test('reads sections with classes and arms in order', () async {
    final (service, requests) = _service(
      (request) => _json([
        {
          'id': 'primary',
          'name': 'Primary',
          'sort_order': 2,
          'is_active': true,
          'classes': [
            {
              'id': 'p2',
              'section_id': 'primary',
              'name': 'Primary 2',
              'sort_order': 2,
              'is_graduating_class': false,
              'is_active': true,
              'class_arms': [],
            },
            {
              'id': 'p1',
              'section_id': 'primary',
              'name': 'Primary 1',
              'sort_order': 1,
              'is_graduating_class': false,
              'is_active': true,
              'class_arms': [
                {
                  'id': 'b',
                  'class_id': 'p1',
                  'name': 'B',
                  'is_active': true,
                  'created_at': '2026-10-14T09:01:00Z',
                },
                {
                  'id': 'a',
                  'class_id': 'p1',
                  'name': 'A',
                  'is_active': true,
                  'created_at': '2026-10-14T09:00:00Z',
                },
              ],
            },
          ],
        },
      ], request),
    );

    final sections = await service.getStructure('kings');

    expect(requests.single.url.path, '/rest/v1/sections');
    expect(requests.single.url.queryParameters['organization_id'], 'eq.kings');
    final classes = sections.single.classes;
    expect(classes.map((c) => c.name), ['Primary 1', 'Primary 2']);
    expect(classes.first.arms.map((arm) => arm.name), ['A', 'B']);
    expect(sections.single.nextClassOrder, 3);
  });

  test('names arms the way schools write them', () {
    expect(fullArmName('JSS 1', 'A'), 'JSS 1A');
    expect(fullArmName('JSS 1', 'Gold'), 'JSS 1 Gold');
  });

  group('refusals become readable messages', () {
    test('a delete row-level security blocks touches nothing', () async {
      final (service, requests) = _service((request) => _json([], request));

      await expectLater(
        service.deleteSection(
          SchoolSection(
            id: 'empty',
            name: 'Creche',
            sortOrder: 4,
            isActive: true,
            classes: const [],
          ),
        ),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            ClassStructureService.leadersOnly,
          ),
        ),
      );
      expect(requests.single.method, 'DELETE');
    });

    test('an arm with students placed in it stays', () async {
      final (service, _) = _service(
        (request) => request.method == 'DELETE'
            ? _refused('23503', request)
            : _json([], request),
      );

      await expectLater(
        service.saveClass(
          _primary1,
          organizationId: 'kings',
          name: 'Primary 1',
          isGraduating: false,
          arms: ['A'],
        ),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            contains('Primary 1B has students or a class teacher'),
          ),
        ),
      );
    });

    test('a class name that is taken', () async {
      final (service, _) = _service((request) => _refused('23505', request));

      await expectLater(
        service.addClass(
          organizationId: 'kings',
          section: _primary,
          name: 'Primary 1',
          isGraduating: false,
          arms: const [],
        ),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            "There's already a class called Primary 1.",
          ),
        ),
      );
    });

    test('a class whose arms could not all be removed stays', () async {
      final (service, requests) = _service(
        // Only one of the two arms comes back as removed.
        (request) => _json([
          {'id': 'a'},
        ], request),
      );

      await expectLater(
        service.deleteClass(_primary1),
        throwsA(isA<SupabaseRefusal>()),
      );
      expect(requests, hasLength(1));
    });

    test('anything else is left for the caller', () async {
      final (service, _) = _service(
        (request) => _json(
          {'code': 'XX000', 'message': 'boom', 'details': null, 'hint': null},
          request,
          status: 500,
        ),
      );

      await expectLater(
        service.setClassActive(_primary1, false),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  test('saving a class removes arms before adding new ones', () async {
    final (service, requests) = _service(
      (request) => _json([
        {'id': 'done'},
      ], request),
    );

    await service.saveClass(
      _primary1,
      organizationId: 'kings',
      name: 'Primary One',
      isGraduating: false,
      arms: ['A', 'Gold'],
    );

    expect(requests.map((request) => request.method), [
      'PATCH',
      'DELETE',
      'POST',
    ]);
    expect(jsonDecode(requests[0].body), {'name': 'Primary One'});
    expect(requests[1].url.queryParameters['id'], 'eq.b');
    expect(jsonDecode(requests[2].body), [
      {'organization_id': 'kings', 'class_id': 'p1', 'name': 'Gold'},
    ]);
  });
}
