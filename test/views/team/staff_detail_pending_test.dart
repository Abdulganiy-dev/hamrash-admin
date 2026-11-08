import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/widgets/invite_ready_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_identity.dart';
import 'package:hamrash_admin/views/team/widgets/staff_details_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_invite_card.dart';

class _FakeTeam implements TeamService {
  _FakeTeam(this.member);

  final StaffMember member;

  @override
  Future<StaffMember> getStaff(String staffId) async => member;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _member = StaffMember(
  id: 's1',
  firstName: 'Tunde',
  lastName: 'Ade',
  jobTitle: 'Teacher',
  phone: '+2348030000000',
  staffType: 'teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 11, 8),
  memberId: 'm1',
  login: StaffLogin(
    id: 'm1',
    role: OrganizationMemberRole.teacher,
    status: OrganizationMemberStatus.invited,
    claimCode: 'K7M2QX9P',
    createdAt: DateTime.now(),
  ),
);

final _school = MemberSchool(
  organization: Organization(
    id: 'kings',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: const [OrganizationMemberRole.owner],
  memberIds: const [],
);

void main() {
  setUp(() {
    locator.registerSingleton<TeamService>(_FakeTeam(_member));
    addTearDown(locator.reset);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: StaffDetailScreen(school: _school, staffId: 's1')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the pending invite is one card, not a big code block', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Invite pending'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffDetailIdentity),
        matching: find.text('Teacher'),
      ),
      findsOneWidget,
    );

    expect(find.byType(StaffInviteCard), findsOneWidget);
    expect(find.text('INVITE CODE'), findsOneWidget);
    expect(find.text('K7M2-QX9P'), findsOneWidget);
    expect(find.text('EXPIRES'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Invited today'), findsNothing);
    expect(find.text('Share code'), findsNothing);
    expect(find.text('View invite code'), findsNothing);
    expect(find.text('Tap or long-press to copy'), findsNothing);

    // Details holds only staff number/type and phone/email.
    expect(find.text('Staff no.'), findsOneWidget);
    expect(find.text('Staff type'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Job title'), findsNothing);
    expect(find.text('Role'), findsNothing);
    expect(find.text('Record'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(StaffDetailsCard),
        matching: find.text('Change'),
      ),
      findsNothing,
    );

    expect(find.text('Cancel invite', skipOffstage: false), findsOneWidget);
    expect(
      find.text(
        'The code stops working. Tunde stays on the staff list.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the invite card opens the invite-ready sheet', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(StaffInviteCard));
    await tester.pumpAndSettle();

    expect(find.byType(InviteReadySheet), findsOneWidget);
    expect(find.text("Tunde's invite is ready"), findsOneWidget);
    expect(find.text('K7M2'), findsOneWidget);
    expect(find.text('QX9P'), findsOneWidget);
  });
}
