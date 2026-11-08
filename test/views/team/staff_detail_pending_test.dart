import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_invite_code.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';

/// Only `getStaff` is used by the page; everything else would be a real
/// database call, which these tests never make.
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

  testWidgets('the pending invite sits straight on the page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StaffDetailScreen(school: _school, staffId: 's1'),
      ),
    );
    await tester.pumpAndSettle();

    // Header row: the tracked label and when it was invited.
    expect(find.text('INVITE CODE · TEACHER'), findsOneWidget);
    expect(find.text('Invited today'), findsOneWidget);

    // The code and its helper.
    expect(find.text('K7M2'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('QX9P'), findsOneWidget);
    expect(find.text('Tap or long-press to copy'), findsOneWidget);

    // The status line and the share button.
    expect(
      find.text(
        'Waiting for Tunde to sign in and enter it. Nothing is emailed, and '
        "the code doesn't expire.",
      ),
      findsOneWidget,
    );
    expect(find.text('Share code'), findsOneWidget);

    // No card, border or well around the code.
    expect(
      find.ancestor(
        of: find.byType(InviteCodeDisplay),
        matching: find.byType(AppCard),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(InviteCodeDisplay),
        matching: find.byWidgetPredicate(
          (widget) => switch (widget) {
            Container(:final color, :final decoration) =>
              color != null || decoration != null,
            DecoratedBox(:final decoration) => decoration is BoxDecoration,
            ColoredBox() => true,
            _ => false,
          },
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('a tap on the pending code copies it', (tester) async {
    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StaffDetailScreen(school: _school, staffId: 's1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InviteCodeDisplay));
    await tester.pump();

    expect(copied, 'K7M2QX9P');
    expect(find.text('Copied to clipboard'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
  });
}
