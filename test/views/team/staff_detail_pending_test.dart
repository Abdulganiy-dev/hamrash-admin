import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/widgets/staff_invite_code_field.dart';

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
  email: 'tunde@example.com',
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
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: StaffDetailScreen(school: _school, staffId: 's1'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the pending invite shows the code field and share button', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Invite pending'), findsOneWidget);
    expect(find.text('Teacher · Teaching'), findsOneWidget);

    expect(find.byType(StaffInviteCodeField), findsOneWidget);
    expect(find.text('INVITE CODE'), findsOneWidget);
    expect(find.text('K7M2-QX9P'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('invite-code-field'))).height,
      64,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('invite-copy-button'))),
      const Size(36, 36),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('invite-share-button'))),
      const Size(36, 36),
    );
    // The share icon sits beside copy inside the field; no separate button.
    expect(find.widgetWithText(AppPrimaryButton, 'Share invite'), findsNothing);
    expect(find.text('Share invite'), findsNothing);
    expect(find.text('EXPIRES'), findsNothing);
    expect(find.text('Invite to Hamrash'), findsNothing);

    // Details hold the record; no Access section for an unused invite.
    expect(find.text('Staff number'), findsOneWidget);
    expect(find.text('Staff type'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsNWidgets(2)); // action label and row
    expect(find.text('Access'), findsNothing);

    expect(find.text('Cancel invite', skipOffstage: false), findsOneWidget);
    expect(
      find.text(
        'The code stops working. Tunde stays on the staff list.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('copy puts the raw code on the clipboard and shows a check', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('invite-copy-button')));
    await tester.pump();
    expect(copied, 'K7M2QX9P');
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('invite-copy-button')),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.icon, AppIcons.check);

    await tester.pump(const Duration(seconds: 2));
    final after = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('invite-copy-button')),
        matching: find.byType(Icon),
      ),
    );
    expect(after.icon, AppIcons.copy);
  });

  testWidgets('the share icon opens the native share sheet with the message', (
    tester,
  ) async {
    final shared = <Map<Object?, Object?>>[];
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'share') {
        shared.add(call.arguments as Map<Object?, Object?>);
      }
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('invite-share-button')));
    await tester.pump();

    expect(shared, hasLength(1));
    expect(shared.single['text'], contains('K7M2-QX9P'));
    expect(shared.single['text'], contains("Hi Tunde, you've been added"));
  });
}
