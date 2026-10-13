import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/api/services/supabase_services/organization_member_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/core/cache/user_prefrences.dart';
import 'package:hamrash_admin/views/home/home_view_model.dart';
import 'package:hamrash_admin/views/onboarding/member_access_view_model.dart';
import 'package:hamrash_admin/views/schools/confirm_school/confirm_school_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _client() =>
    SupabaseClient('https://example.supabase.co', 'test-key');

Organization _org(
  String id,
  String name, {
  OrganizationStatus status = OrganizationStatus.trial,
  DateTime? confirmedAt,
}) => Organization(
  id: id,
  code: 'HMR-000001',
  name: name,
  status: status,
  createdBy: 'platform',
  numberPrefix: 'KCL',
  detailsConfirmedAt: confirmedAt,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

OrganizationMember _member(
  Organization org,
  OrganizationMemberRole role, {
  OrganizationMemberStatus status = OrganizationMemberStatus.active,
}) => OrganizationMember(
  id: '${org.id}-${role.value}',
  organizationId: org.id,
  clerkUserId: 'user-1',
  role: role,
  status: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  organization: org,
);

class _Members extends OrganizationMemberService {
  _Members(this.memberships) : super(_client());

  final List<OrganizationMember> memberships;

  @override
  Future<List<OrganizationMember>> getMembershipsWithOrganizations(
    String clerkUserId,
  ) async => memberships;
}

class _Schools extends SchoolService {
  _Schools(this.progress, {this.ownerName}) : super(_client());

  final SetupProgress progress;
  final String? ownerName;

  @override
  Future<SetupProgress> getSetupProgress(Organization organization) async =>
      progress;

  @override
  Future<String?> getOwnerName(String organizationId) async => ownerName;
}

void main() {
  final kings = _org('kings', 'Kings College');
  final lagoon = _org(
    'lagoon',
    'Lagoon Prep',
    status: OrganizationStatus.suspended,
  );
  final closed = _org(
    'closed',
    'Old School',
    status: OrganizationStatus.archived,
  );

  group('MemberSchool.fromMemberships', () {
    test('groups roles per school, highest first, sorted by name', () {
      final schools = MemberSchool.fromMemberships([
        _member(lagoon, OrganizationMemberRole.bursar),
        _member(kings, OrganizationMemberRole.principal),
        _member(kings, OrganizationMemberRole.owner),
        _member(lagoon, OrganizationMemberRole.admin),
      ]);

      expect(schools.map((s) => s.name), ['Kings College', 'Lagoon Prep']);
      expect(schools[0].rolesLabel, 'Owner · Principal');
      expect(schools[1].rolesLabel, 'Admin · Bursar');
      expect(schools[1].isPaused, isTrue);
    });

    test('leaves out archived schools, invites and non-admin roles', () {
      final schools = MemberSchool.fromMemberships([
        _member(closed, OrganizationMemberRole.owner),
        _member(
          kings,
          OrganizationMemberRole.admin,
          status: OrganizationMemberStatus.invited,
        ),
        _member(kings, OrganizationMemberRole.teacher),
      ]);
      expect(schools, isEmpty);
    });

    test('only owners and admins check details, and only once', () {
      final principal = MemberSchool(
        organization: kings,
        roles: const [OrganizationMemberRole.principal],
      );
      final owner = MemberSchool(
        organization: kings,
        roles: const [OrganizationMemberRole.owner],
      );
      final checked = MemberSchool(
        organization: _org(
          'kings',
          'Kings College',
          confirmedAt: DateTime(2026),
        ),
        roles: const [OrganizationMemberRole.owner],
      );
      expect(principal.needsDetailsCheck, isFalse);
      expect(owner.needsDetailsCheck, isTrue);
      expect(checked.needsDetailsCheck, isFalse);
    });
  });

  group('MemberAccessViewModel', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      UserPreference.instance = null;
    });

    Future<MemberAccessViewModel> checked(
      List<OrganizationMember> memberships,
    ) async {
      final model = MemberAccessViewModel(
        'user-1',
        service: _Members(memberships),
      );
      await model.check();
      return model;
    }

    test('one school opens straight away', () async {
      final model = await checked([
        _member(kings, OrganizationMemberRole.owner),
      ]);
      expect(model.selected?.id, 'kings');
      expect(model.canSwitchSchool, isFalse);
    });

    test('several schools wait for a pick, then remember it', () async {
      final memberships = [
        _member(kings, OrganizationMemberRole.owner),
        _member(lagoon, OrganizationMemberRole.admin),
      ];
      final first = await checked(memberships);
      expect(first.selected, isNull);

      first.selectSchool(first.schools.last);
      await Future<void>.delayed(Duration.zero);

      final next = await checked(memberships);
      expect(next.selected?.id, 'lagoon');

      next.switchSchool();
      expect(next.selected, isNull);
    });

    test('a paused-only member gets the school, not the join screen', () async {
      final model = await checked([
        _member(lagoon, OrganizationMemberRole.admin),
      ]);
      expect(model.hasMembership, isTrue);
      expect(model.selected?.isPaused, isTrue);
    });

    test('updateSchool swaps in the saved details', () async {
      final model = await checked([
        _member(kings, OrganizationMemberRole.owner),
      ]);
      model.updateSchool(
        _org('kings', 'Kings College', confirmedAt: DateTime(2026, 10)),
      );
      expect(model.selected?.needsDetailsCheck, isFalse);
    });
  });

  group('SetupProgress', () {
    test('current is the first step not done', () {
      const progress = SetupProgress({SetupStep.schoolDetails});
      expect(progress.current, SetupStep.academicCalendar);
      expect(progress.doneCount, 1);
      expect(progress.remainingAfterCurrent, 5);
      expect(SetupProgress(SetupStep.values.toSet()).current, isNull);
    });
  });

  group('HomeViewModel', () {
    MemberSchool school(OrganizationMemberRole role) =>
        MemberSchool(organization: kings, roles: [role]);

    test('session name follows the September start', () {
      final october = HomeViewModel(
        school: school(OrganizationMemberRole.owner),
        service: _Schools(const SetupProgress({})),
        now: () => DateTime(2026, 10, 13),
      );
      final march = HomeViewModel(
        school: school(OrganizationMemberRole.owner),
        service: _Schools(const SetupProgress({})),
        now: () => DateTime(2027, 3, 1),
      );
      expect(october.currentSessionName, '2026/27');
      expect(march.currentSessionName, '2026/27');
      expect(
        october.hintFor(SetupStep.academicCalendar),
        'Add 2026/27 and the current term',
      );
    });

    test('principals see who is setting the school up', () async {
      final model = HomeViewModel(
        school: school(OrganizationMemberRole.principal),
        service: _Schools(
          const SetupProgress({SetupStep.schoolDetails}),
          ownerName: 'Amina Bello',
        ),
      );
      await model.load();
      expect(model.statusLine, 'Trial · Setting up');
      expect(
        model.beingSetUpMessage,
        startsWith('Amina Bello, the owner, is getting Kings College ready.'),
      );
    });
  });

  group('SchoolField', () {
    test('cleans and checks what was typed', () {
      expect(SchoolField.phone.clean('+234 803 555 0142'), '+2348035550142');
      expect(SchoolField.phone.validate('+2348035550142'), isNull);
      expect(SchoolField.numberPrefix.clean(' kcl '), 'KCL');
      expect(SchoolField.numberPrefix.validate('K'), isNotNull);
      expect(
        SchoolField.numberPrefix.validate(null),
        'Number prefix is required',
      );
      expect(SchoolField.address.validate(null), isNull);
      expect(SchoolField.email.validate('hello@kingscollege.ng'), isNull);
    });
  });
}
