import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_rows.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

/// Distance from the bottom of the header to the top of the card.
double _gap(WidgetTester tester) {
  final header = tester.getBottomLeft(find.byType(AppSectionHeader)).dy;
  final card = tester.getTopLeft(find.byType(AppCard)).dy;
  return card - header;
}

void main() {
  testWidgets('rows share one white card with a hairline between them', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AppSectionCard(
          title: 'Details',
          children: [
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

    final card = find.byType(AppCard);
    expect(card, findsOneWidget);
    final rows = find.byType(StaffInfoRow);
    final first = tester.getRect(rows.first);
    final second = tester.getRect(rows.last);
    // The card's 1px border and 4px top padding, then 52 rows with a 1px
    // hairline between.
    expect(first.top, tester.getRect(card).top + 5);
    expect(first.height, 52);
    expect(second.top, closeTo(first.bottom + 1, 0.5));
    expect(find.byType(AppDivider), findsOneWidget);
  });

  testWidgets('the card draws the dividers, from dividerIndent', (tester) async {
    await tester.pumpWidget(
      _host(
        const AppSectionCard(
          title: 'JSS 1A',
          padding: EdgeInsets.zero,
          dividerIndent: 72,
          dividerEndIndent: 16,
          children: [Text('Ada'), Text('Bayo'), Text('Chi')],
        ),
      ),
    );

    final dividers = tester.widgetList<AppDivider>(find.byType(AppDivider));
    expect(dividers, hasLength(2));
    expect(dividers.every((d) => d.indent == 72 && d.endIndent == 16), isTrue);
  });

  testWidgets('without an action the card sits 12 below the header', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AppSectionCard(title: 'Parents', children: [Text('Ngozi')]),
      ),
    );
    expect(_gap(tester), 12);
  });

  testWidgets('with an action there is no gap: the tap box is the space', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AppSectionCard(
          title: 'Parents',
          action: AppSectionAction(
            label: 'Edit',
            icon: AppIcons.pencil,
            onPressed: () {},
          ),
          children: const [Text('Ngozi')],
        ),
      ),
    );
    expect(_gap(tester), 0);
  });

  testWidgets('a trailing count (not an action) keeps the 12 gap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AppSectionCard(
          title: 'JSS 1A',
          trailing: Text('32 students'),
          children: [
            Text('Ada'),
          ],
        ),
      ),
    );
    expect(_gap(tester), 12);
    expect(find.text('32 students'), findsOneWidget);
  });
}
