import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/views/team/widgets/staff_details_card.dart';

void main() {
  Widget host(Widget card) => MaterialApp(
    home: Scaffold(body: Center(child: SizedBox(width: 358, child: card))),
  );

  testWidgets('the card is two bands of two cells', (tester) async {
    await tester.pumpWidget(
      host(
        const StaffDetailsCard(
          staffNumber: 'KCL/STF/0001',
          staffType: 'Non-teaching',
          phone: '+2348035550142',
          email: 'vice.principal@example.com',
        ),
      ),
    );

    for (final label in ['Staff no.', 'Staff type', 'Phone', 'Email']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Job title'), findsNothing);
    expect(find.text('Role'), findsNothing);
    expect(find.text('Record'), findsNothing);

    final band1 = find.byKey(const ValueKey('details-band-1'));
    final band2 = find.byKey(const ValueKey('details-band-2'));
    for (final band in [band1, band2]) {
      expect(tester.getSize(band).height, 56);
    }

    final divider1 = find.byKey(const ValueKey('details-divider-1'));
    final divider2 = find.byKey(const ValueKey('details-divider-2'));
    expect(tester.getSize(divider1).width, 1);
    expect(tester.getSize(divider2).width, 1);
    final cardCenter = tester.getCenter(find.byType(StaffDetailsCard)).dx;
    expect(tester.getCenter(divider1).dx, closeTo(cardCenter, 0.5));
    expect(tester.getCenter(divider2).dx, closeTo(cardCenter, 0.5));

    expect(find.byKey(const ValueKey('details-hairline-1')), findsOneWidget);

    // Faint stone-100 rules; the vertical one spans the whole band.
    for (final divider in [divider1, divider2]) {
      expect(tester.getSize(divider).height, 56);
      final fill = tester.widget<ColoredBox>(
        find.descendant(of: divider, matching: find.byType(ColoredBox)),
      );
      expect(fill.color, AppPalette.stone100);
    }
    final hairline = find.byKey(const ValueKey('details-hairline-1'));
    final hairlineFill = tester.widget<ColoredBox>(
      find.descendant(of: hairline, matching: find.byType(ColoredBox)),
    );
    expect(hairlineFill.color, AppPalette.stone100);
  });

  testWidgets('fallbacks read "Not set" and "Not added"', (tester) async {
    await tester.pumpWidget(
      host(const StaffDetailsCard(staffNumber: null, staffType: 'Teaching')),
    );

    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Not added'), findsNWidgets(2));
  });

  testWidgets('long values ellipsise without overflowing at 320', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 288,
          child: StaffDetailsCard(
            staffNumber: 'KCL/STF/0001',
            staffType: 'Non-teaching',
            phone: '+2348035550142',
            email: 'avery.long.email.address.for.one.teacher@example.school',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final email = tester.renderObject<RenderParagraph>(
      find.text('avery.long.email.address.for.one.teacher@example.school'),
    );
    expect(email.didExceedMaxLines, isTrue);
  });
}
