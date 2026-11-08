import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_identity.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends UrlLauncherPlatform {
  final List<String> opened = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return true;
  }
}

StaffMember _member({
  String? phone = '0803 555 0142',
  String? email = 'a@b.ng',
}) => StaffMember(
  id: 's1',
  firstName: 'Tunde',
  lastName: 'Ade',
  jobTitle: 'Teacher',
  phone: phone,
  email: email,
  staffType: 'teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 11, 8),
);

void main() {
  late _FakeLauncher launcher;
  late UrlLauncherPlatform original;

  setUp(() {
    original = UrlLauncherPlatform.instance;
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });
  tearDown(() => UrlLauncherPlatform.instance = original);

  Future<void> pump(
    WidgetTester tester, {
    required StaffAccess access,
    StaffMember? member,
    double width = 358,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: StaffDetailIdentity(
                member: member ?? _member(),
                access: access,
                meta: 'Teacher · Teaching',
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration avatarDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('identity-avatar')),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('not on the app: stone 80 avatar, neutral pill, centred', (
    tester,
  ) async {
    await pump(tester, access: StaffAccess.notOnApp);

    expect(avatarDecoration(tester).color, AppPalette.stone100);
    expect(
      tester.getSize(find.byKey(const ValueKey('identity-avatar'))),
      const Size(80, 80),
    );
    expect(find.text('TA'), findsOneWidget);
    expect(find.text('Not on app'), findsOneWidget);
    expect(find.text('Teacher · Teaching'), findsOneWidget);

    final name = tester.widget<Text>(find.text('Tunde Ade'));
    expect(name.style?.fontSize, 26);
    expect(name.style?.fontWeight, FontWeight.w800);
    expect(name.textAlign, TextAlign.center);
    for (final text in ['Tunde Ade', 'Teacher · Teaching']) {
      expect(tester.getCenter(find.text(text)).dx, closeTo(400, 0.5));
    }
  });

  testWidgets('invite pending: aubergine avatar with a dashed ring', (
    tester,
  ) async {
    await pump(tester, access: StaffAccess.invitePending);

    final decoration = avatarDecoration(tester);
    expect(decoration.color, LightColors.primaryPrimaryMute);
    expect(decoration.border, isNull);
    final painter =
        tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byKey(const ValueKey('identity-avatar')),
                matching: find.byType(CustomPaint),
              ),
            )
            .foregroundPainter;
    expect(painter, isNotNull);
    expect(find.text('Invite pending'), findsOneWidget);
  });

  testWidgets('on the app: teal avatar and success pill', (tester) async {
    await pump(tester, access: StaffAccess.onApp);

    expect(avatarDecoration(tester).color, LightColors.categoryTealMute);
    expect(find.text('On app'), findsOneWidget);
  });

  testWidgets('suspended keeps the error pill', (tester) async {
    await pump(tester, access: StaffAccess.suspended);
    expect(find.text('Suspended'), findsOneWidget);
  });

  testWidgets('three 56 circles launch tel, sms and mailto', (tester) async {
    await pump(tester, access: StaffAccess.onApp);

    for (final key in ['call', 'message', 'email']) {
      final circle = find.descendant(
        of: find.byKey(ValueKey('action-$key')),
        matching: find.byType(Container),
      );
      expect(tester.getSize(circle.first), const Size(56, 56));
    }
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('action-call')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('action-message')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('action-email')));
    await tester.pump();
    expect(launcher.opened, [
      'tel:+2348035550142',
      'sms:+2348035550142',
      'mailto:a@b.ng',
    ]);
  });

  testWidgets('a missing phone disables Call and Message only', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, access: StaffAccess.onApp, member: _member(phone: null));

    await tester.tap(find.byKey(const ValueKey('action-call')));
    await tester.tap(find.byKey(const ValueKey('action-message')));
    await tester.pump();
    expect(launcher.opened, isEmpty);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('action-call'))),
      isSemantics(label: 'Call Tunde', isButton: true, isEnabled: false),
    );

    await tester.tap(find.byKey(const ValueKey('action-email')));
    await tester.pump();
    expect(launcher.opened, ['mailto:a@b.ng']);
    handle.dispose();
  });

  testWidgets('a missing email disables Email only', (tester) async {
    await pump(tester, access: StaffAccess.onApp, member: _member(email: ' '));

    await tester.tap(find.byKey(const ValueKey('action-email')));
    await tester.pump();
    expect(launcher.opened, isEmpty);

    await tester.tap(find.byKey(const ValueKey('action-call')));
    await tester.pump();
    expect(launcher.opened, ['tel:+2348035550142']);
  });

  testWidgets('fits at 320 with a long name', (tester) async {
    await pump(
      tester,
      access: StaffAccess.invitePending,
      width: 288,
      member: StaffMember(
        id: 's1',
        firstName: 'Chidinma-Adaeze',
        lastName: 'Okonkwo-Nwankwo-Onyekachukwu',
        jobTitle: 'Teacher',
        staffType: 'teaching',
        status: StaffRecordStatus.active,
        createdAt: DateTime(2026, 11, 8),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
