import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/organization_models/school_area.dart';
import 'package:hamrash_admin/api/models/organization_models/school_snapshot.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/views/more/more_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Schools extends SchoolService {
  _Schools({this.progress = const SetupProgress({}), this.term})
    : super(SupabaseClient('https://example.supabase.co', 'test-key'));

  final SetupProgress progress;
  final CurrentTerm? term;
  final TeamCount team = const TeamCount(active: 4, invited: 1);
  bool askedForTeam = false;

  @override
  Future<SetupProgress> getSetupProgress(Organization organization) async =>
      progress;

  @override
  Future<CurrentTerm?> getCurrentTerm(String organizationId) async => term;

  @override
  Future<TeamCount> getTeamCount(String organizationId) async {
    askedForTeam = true;
    return team;
  }
}

MemberSchool _school(OrganizationMemberRole role) => MemberSchool(
  organization: Organization(
    id: 'kings',
    code: 'HMR-000001',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: [role],
);

void main() {
  group('MemberSchool.accessTo matches the database rules', () {
    test('the owner manages everything', () {
      final owner = _school(OrganizationMemberRole.owner);
      for (final area in SchoolArea.values) {
        expect(owner.accessTo(area), AreaAccess.manage, reason: area.name);
      }
    });

    test('admins, principals and VPs manage all but school details', () {
      for (final role in [
        OrganizationMemberRole.admin,
        OrganizationMemberRole.principal,
        OrganizationMemberRole.vicePrincipal,
      ]) {
        final school = _school(role);
        expect(school.accessTo(SchoolArea.academicCalendar), AreaAccess.manage);
        expect(school.accessTo(SchoolArea.team), AreaAccess.manage);
        expect(school.accessTo(SchoolArea.schoolDetails), AreaAccess.view);
      }
    });

    test("bursars view setup areas and don't see the team", () {
      final bursar = _school(OrganizationMemberRole.bursar);
      expect(bursar.accessTo(SchoolArea.academicCalendar), AreaAccess.view);
      expect(bursar.accessTo(SchoolArea.grading), AreaAccess.view);
      expect(bursar.accessTo(SchoolArea.schoolDetails), AreaAccess.view);
      expect(bursar.accessTo(SchoolArea.team), AreaAccess.none);
    });
  });

  group('MoreViewModel', () {
    test('leaders see every area with live status lines', () async {
      final service = _Schools(
        progress: const SetupProgress({SetupStep.academicCalendar}),
        term: const CurrentTerm(sessionName: '2026/27', termName: 'First term'),
      );
      final model = MoreViewModel(
        school: _school(OrganizationMemberRole.principal),
        service: service,
      );
      await model.load();

      expect(model.areas, SchoolArea.values);
      expect(model.areasTitle, 'Run your school');
      expect(model.calendarSetUp, isTrue);
      expect(
        model.statusFor(SchoolArea.academicCalendar),
        '2026/27 · First term',
      );
      expect(model.statusFor(SchoolArea.classes), 'Not set up yet');
      expect(model.statusFor(SchoolArea.team), '4 people · 1 invite');
      expect(model.blockedReason(SchoolArea.academicCalendar), isNull);
      expect(
        model.blockedReason(SchoolArea.schoolDetails),
        "Only the owner can change the school's details",
      );
    });

    test("bursars can't open setup areas and never load the team", () async {
      final service = _Schools();
      final model = MoreViewModel(
        school: _school(OrganizationMemberRole.bursar),
        service: service,
      );
      await model.load();

      expect(model.areas, isNot(contains(SchoolArea.team)));
      expect(model.areasTitle, 'About your school');
      expect(service.askedForTeam, isFalse);
      expect(model.blockedReason(SchoolArea.academicCalendar), isNotNull);
      expect(model.statusFor(SchoolArea.academicCalendar), 'Not set up yet');
    });
  });

  test('TeamCount reads naturally', () {
    expect(const TeamCount(active: 1, invited: 0).label, '1 person');
    expect(
      const TeamCount(active: 3, invited: 2).label,
      '3 people · 2 invites',
    );
  });
}
