import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_identity.dart';

final _member = StaffMember(
  id: 's1',
  firstName: 'Tunde',
  lastName: 'Ade',
  jobTitle: 'Teacher',
  staffType: 'teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 11, 8),
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required StaffAccess access,
    required String meta,
    VoidCallback? onContact,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 358,
              child: StaffDetailIdentity(
                member: _member,
                access: access,
                meta: meta,
                onContact: onContact ?? () {},
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

  testWidgets('not on the app: stone avatar and neutral pill', (tester) async {
    await pump(tester, access: StaffAccess.notOnApp, meta: 'Teacher');

    final decoration = avatarDecoration(tester);
    expect(decoration.color, AppPalette.stone100);
    expect((decoration.border! as Border).top.color, AppPalette.stone200);
    expect(find.text('TA'), findsOneWidget);
    expect(find.text('Not on app'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);

    final name = tester.widget<Text>(find.text('Tunde Ade'));
    expect(name.style?.fontSize, 24);
    expect(name.style?.fontWeight, FontWeight.w800);
  });

  testWidgets('invite pending: aubergine avatar with a dashed ring', (
    tester,
  ) async {
    await pump(tester, access: StaffAccess.invitePending, meta: 'Teacher');

    final decoration = avatarDecoration(tester);
    expect(decoration.color, LightColors.primaryPrimaryMute);
    expect(decoration.border, isNull);
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('identity-avatar')),
            matching: find.byType(CustomPaint),
          ),
        )
        .foregroundPainter;
    expect(painter, isNotNull);
    expect(find.text('Invite pending'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
  });

  testWidgets('on the app: teal avatar and success pill', (tester) async {
    await pump(tester, access: StaffAccess.onApp, meta: 'Teacher');

    final decoration = avatarDecoration(tester);
    expect(decoration.color, LightColors.categoryTealMute);
    expect(
      (decoration.border! as Border).top.color,
      LightColors.categoryTealMute,
    );
    expect(find.text('On app'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
  });

  testWidgets('suspended keeps the error pill', (tester) async {
    await pump(tester, access: StaffAccess.suspended, meta: 'Teacher');
    expect(find.text('Suspended'), findsOneWidget);
  });

  testWidgets('the round contact button is 44 and fires', (tester) async {
    var taps = 0;
    await pump(
      tester,
      access: StaffAccess.onApp,
      meta: 'Teacher',
      onContact: () => taps++,
    );

    final button = find.byKey(const ValueKey('staff-contact-button'));
    expect(tester.getSize(button), const Size(44, 44));
    await tester.tap(button);
    expect(taps, 1);
  });
}
