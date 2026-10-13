import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/api/models/organization_models/staff_profile.dart';
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
  _Schools(this.progress, {this.ownerName, this.me}) : super(_client());

  SetupProgress progress;
  bool fail = false;
  final String? ownerName;
  final StaffProfile? me;
  List<String>? askedMemberIds;

  @override
  Future<StaffProfile?> getMyStaffProfile(
    String organizationId,
    List<String> memberIds,
  ) async {
    askedMemberIds = memberIds;
    return me;
  }

  @override
  Future<SetupProgress> getSetupProgress(Organization organization) async {
    if (fail) throw StateError('offline');
    return progress;
  }

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
      expect(schools[0].memberIds, ['kings-principal', 'kings-owner']);
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
        signedInName: 'Signed In',
        school: school(OrganizationMemberRole.owner),
        service: _Schools(const SetupProgress({})),
        now: () => DateTime(2026, 10, 13),
      );
      final march = HomeViewModel(
        signedInName: 'Signed In',
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

    test('principals and VPs run setup, except details and invites', () {
      for (final role in [
        OrganizationMemberRole.principal,
        OrganizationMemberRole.vicePrincipal,
      ]) {
        final model = HomeViewModel(
          signedInName: 'Signed In',
          school: school(role),
          service: _Schools(const SetupProgress({})),
        );
        expect(model.school.canRunSetup, isTrue);
        expect(model.canOpen(SetupStep.academicCalendar), isTrue);
        expect(model.canOpen(SetupStep.grading), isTrue);
        expect(model.canOpen(SetupStep.schoolDetails), isFalse);
        expect(model.canOpen(SetupStep.team), isFalse);
        expect(
          model.hintFor(SetupStep.team),
          'The owner or an admin does this',
        );
      }
    });

    test('owners and admins can open every step', () {
      final model = HomeViewModel(
        signedInName: 'Signed In',
        school: school(OrganizationMemberRole.admin),
        service: _Schools(const SetupProgress({})),
      );
      expect(SetupStep.values.every(model.canOpen), isTrue);
    });

    test('bursars see who is setting the school up', () async {
      final model = HomeViewModel(
        signedInName: 'Signed In',
        school: school(OrganizationMemberRole.bursar),
        service: _Schools(
          const SetupProgress({SetupStep.schoolDetails}),
          ownerName: 'Amina Bello',
        ),
      );
      expect(model.school.canRunSetup, isFalse);
      expect(model.canOpen(SetupStep.academicCalendar), isFalse);
      await model.load();
      expect(model.statusLine, 'Trial · Setting up');
      expect(
        model.beingSetUpMessage,
        startsWith('Amina Bello, the owner, is getting Kings College ready.'),
      );
    });
  });

  group('Home refresh', () {
    final school = MemberSchool(
      organization: kings,
      roles: const [OrganizationMemberRole.owner],
    );

    test(
      'a failed refresh keeps the card and rethrows for the toast',
      () async {
        final service = _Schools(
          const SetupProgress({SetupStep.schoolDetails}),
        );
        final model = HomeViewModel(
          school: school,
          signedInName: 'Amina',
          service: service,
        );
        await model.load();

        service.fail = true;
        await expectLater(model.refresh(), throwsStateError);
        expect(model.error, isNull);
        expect(model.progress?.doneCount, 1);

        service
          ..fail = false
          ..progress = const SetupProgress({
            SetupStep.schoolDetails,
            SetupStep.academicCalendar,
          });
        await model.refresh();
        expect(model.progress?.doneCount, 2);
      },
    );

    test('a first load that fails shows the error view', () async {
      final model = HomeViewModel(
        school: school,
        signedInName: 'Amina',
        service: _Schools(const SetupProgress({}))..fail = true,
      );
      await model.load();
      expect(model.error, isNotNull);
    });
  });

  group('own staff record', () {
    final school = MemberSchool(
      organization: kings,
      roles: const [OrganizationMemberRole.owner],
      memberIds: const ['kings-owner'],
    );

    test('Home shows the name the school knows them by', () async {
      final service = _Schools(
        const SetupProgress({}),
        me: const StaffProfile(
          id: 'staff-1',
          firstName: 'Amina',
          lastName: 'Bello',
          photoUrl: 'https://example.com/amina.png',
        ),
      );
      final model = HomeViewModel(
        school: school,
        signedInName: 'amina.b',
        signedInImageUrl: 'https://example.com/google.png',
        service: service,
      );
      expect(model.displayName, 'amina.b');

      await model.load();
      expect(service.askedMemberIds, ['kings-owner']);
      expect(model.displayName, 'Amina Bello');
      expect(model.photoUrl, 'https://example.com/amina.png');
    });

    test('falls back to the sign-in account without a staff record', () async {
      final model = HomeViewModel(
        school: school,
        signedInName: 'Amina',
        signedInImageUrl: 'https://example.com/google.png',
        service: _Schools(const SetupProgress({})),
      );
      await model.load();
      expect(model.displayName, 'Amina');
      expect(model.photoUrl, 'https://example.com/google.png');
    });

    test('the welcome uses the staff first name', () async {
      final model = ConfirmSchoolViewModel(
        organization: kings,
        firstName: null,
        memberIds: const ['kings-owner'],
        onConfirmed: (_) {},
        service: _Schools(
          const SetupProgress({}),
          me: const StaffProfile(
            id: 'staff-1',
            firstName: 'Amina',
            lastName: 'Bello',
          ),
        ),
      );
      expect(model.greeting, 'Welcome');
      await model.load();
      expect(model.greeting, 'Welcome, Amina');
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
