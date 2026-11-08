import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/add_staff/add_staff_screen.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/team_screen.dart';
import 'package:hamrash_admin/views/team/widgets/staff_danger_action.dart';

/// Footer layout on the three team screens. The screens are pumped at the
/// 390x844 artboard size with a 34px home-indicator inset, so the measurements
/// match the Paper frames.
const _screen = Size(390, 844);
const _homeIndicator = 34.0;

class _FakeTeam implements TeamService {
  _FakeTeam({this.member, List<StaffMember>? people})
    : people = people ?? const [];

  final StaffMember? member;
  final List<StaffMember> people;

  @override
  Future<StaffMember> getStaff(String staffId) async => member!;

  @override
  Future<List<StaffMember>> listStaff(String organizationId) async => people;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  memberIds: const ['m-owner'],
);

StaffMember _member({StaffLogin? login}) => StaffMember(
  id: 's1',
  firstName: 'Tunde',
  lastName: 'Ade',
  jobTitle: 'Teacher',
  phone: '+2348030000000',
  staffType: 'teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 11, 8),
  memberId: login?.id,
  login: login,
);

final _pending = StaffLogin(
  id: 'm1',
  role: OrganizationMemberRole.teacher,
  status: OrganizationMemberStatus.invited,
  claimCode: 'K7M2QX9P',
  createdAt: DateTime(2026, 11, 5),
);

Future<void> _setUp(WidgetTester tester) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: _homeIndicator);
  addTearDown(tester.view.reset);
  addTearDown(locator.reset);
}

/// Edges of the bar in a DefaultScaffold: the opaque surface behind it.
Finder get _barSurface => find.byKey(const ValueKey('bottom-bar-surface'));

/// The bar's surface is full width and runs to the bottom edge (it is opaque
/// under the home indicator); its content stays above the safe-area inset.
void _expectFullWidthBar(WidgetTester tester, Finder content) {
  expect(
    tester.getSize(_barSurface).width,
    _screen.width,
    reason: 'bottom bar must span the full screen width',
  );
  expect(tester.getBottomLeft(_barSurface).dy, _screen.height);
  expect(
    tester.getBottomLeft(content).dy,
    lessThanOrEqualTo(_screen.height - _homeIndicator),
    reason: 'bar content must sit above the home-indicator safe area',
  );
}

void _expectCentred(WidgetTester tester, Finder finder) {
  expect(
    tester.getCenter(finder).dx,
    closeTo(_screen.width / 2, 0.5),
    reason: 'text must be centred horizontally',
  );
}

void main() {
  // Real Nunito metrics, so text widths match the app rather than the wider
  // test fallback font.
  setUpAll(() async {
    final loader = FontLoader('Nunito');
    for (final file in ['Regular', 'Bold', 'ExtraBold']) {
      loader.addFont(rootBundle.load('assets/fonts/Nunito-$file.ttf'));
    }
    await loader.load();
  });

  testWidgets('Staffs list: Add staff member spans the gutters', (
    tester,
  ) async {
    await _setUp(tester);
    locator.registerSingleton<TeamService>(_FakeTeam(people: [_member()]));

    await tester.pumpWidget(MaterialApp(home: TeamScreen(school: _school)));
    await tester.pumpAndSettle();

    final button = find.byType(AppPrimaryButton);
    _expectFullWidthBar(tester, button);
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, _screen.width - 32);
    expect(tester.getSize(button).height, 56);
    expect(tester.getTopLeft(button).dx, 16);
  });

  testWidgets('the danger action centres its title and caption in the bar', (
    tester,
  ) async {
    // Same bar the staff detail page builds, without the page's details card.
    await _setUp(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultScaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: StaffDangerAction(
                label: 'Remove from staff list',
                caption: 'Tunde stays in the school records.',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('Remove from staff list');
    final caption = find.text('Tunde stays in the school records.');
    _expectFullWidthBar(tester, caption);
    _expectCentred(tester, title);
    _expectCentred(tester, caption);
  });

  testWidgets('Staff detail (active): remove action is centred in a full bar', (
    tester,
  ) async {
    await _setUp(tester);
    locator.registerSingleton<TeamService>(_FakeTeam(member: _member()));

    await tester.pumpWidget(
      MaterialApp(home: StaffDetailScreen(school: _school, staffId: 's1')),
    );
    await tester.pumpAndSettle();

    final title = find.text('Remove from staff list');
    _expectFullWidthBar(tester, title);
    expect(tester.getSize(_barSurface).height, 72 + _homeIndicator);
    expect(find.byKey(const ValueKey('bottom-bar-fade')), findsNothing);
    final caption =
        find
            .descendant(
              of: find.byType(StaffDangerAction),
              matching: find.byType(AppText),
            )
            .last;
    expect(title, findsOneWidget);
    expect(caption, findsOneWidget);
    _expectCentred(tester, title);
    _expectCentred(tester, caption);
  });

  testWidgets('Staff detail (invite pending): cancel action is centred', (
    tester,
  ) async {
    await _setUp(tester);
    locator.registerSingleton<TeamService>(
      _FakeTeam(member: _member(login: _pending)),
    );

    await tester.pumpWidget(
      MaterialApp(home: StaffDetailScreen(school: _school, staffId: 's1')),
    );
    await tester.pumpAndSettle();

    final title = find.text('Cancel invite');
    _expectFullWidthBar(tester, title);
    expect(title, findsOneWidget);
    _expectCentred(tester, title);
    final danger = find.byType(StaffDangerAction);
    expect(tester.getSize(danger).width, _screen.width - 32);
  });

  testWidgets('Add Staff: Save staff member spans the gutters', (tester) async {
    await _setUp(tester);
    locator.registerSingleton<TeamService>(_FakeTeam());

    await tester.pumpWidget(MaterialApp(home: AddStaffScreen(school: _school)));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(AppPrimaryButton, 'Save staff member');
    _expectFullWidthBar(tester, save);
    expect(tester.getSize(save).width, _screen.width - 32);
    final another = find.text('Save and add another');
    expect(another, findsOneWidget);
    _expectCentred(tester, another);
  });
}
