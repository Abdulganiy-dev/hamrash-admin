import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 390,
          child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
        ),
      ),
    ),
  );

  testWidgets('an action sits flush right in the 32 header', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        StaffInfoSection(
          title: 'Details',
          headerKey: const ValueKey('details-header'),
          action: AppSectionAction(
            label: 'Change',
            icon: AppIcons.pencil,
            semanticLabel: 'Change details',
            onPressed: () => taps++,
          ),
          rows: const [
            StaffInfoRow(icon: AppIcons.phone, label: 'Phone', value: null),
          ],
        ),
      ),
    );

    final header = find.byKey(const ValueKey('details-header'));
    final action = find.byType(AppSectionAction);
    expect(tester.getSize(header).height, 32);
    expect(
      tester.getTopRight(action).dx,
      closeTo(tester.getTopRight(header).dx, 0.5),
    );

    await tester.tap(action);
    expect(taps, 1);
  });

  testWidgets('rows share one white card with a hairline between them', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        StaffInfoSection(
          title: 'Details',
          headerKey: const ValueKey('details-header'),
          trailing: const Text('Caption'),
          rows: const [
            StaffInfoRow(
              icon: AppIcons.phone,
              label: 'Phone',
              value: '0803 555 0142',
            ),
            StaffInfoRow(
              icon: AppIcons.mail,
              label: 'Email',
              value: 'tunde@example.com',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Caption'), findsOneWidget);
    expect(find.byType(AppSectionAction), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('details-header'))).height, 32);

    final card = find.byType(AppCard);
    expect(card, findsOneWidget);
    final decoration =
        tester.widget<Container>(
          find.descendant(of: card, matching: find.byType(Container)).first,
        ).decoration!
            as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(20));

    final rows = find.byType(StaffInfoRow);
    expect(rows, findsNWidgets(2));
    final first = tester.getRect(rows.first);
    final second = tester.getRect(rows.last);
    // The card's 1px border and 4px top padding, then 52 rows with 1px
    // hairlines between.
    expect(first.top, tester.getRect(card).top + 5);
    expect(first.height, 52);
    expect(second.height, 52);
    expect(second.top, closeTo(first.bottom + 1, 0.5));
    expect(find.byType(AppDivider), findsOneWidget);
  });
}
