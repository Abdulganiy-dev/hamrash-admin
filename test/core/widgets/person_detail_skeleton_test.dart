import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/person_detail_skeleton.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_rows.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

/// Height of the (first) card and of the header above it.
({double card, double header}) _measure(WidgetTester tester) {
  final card = tester.getSize(find.byType(AppCard).first).height;
  final header = tester.getSize(find.byType(AppSectionHeader)).height;
  return (card: card, header: header);
}

void main() {
  testWidgets('a details card is as tall as the real one', (tester) async {
    await tester.pumpWidget(
      _host(
        AppSectionCard(
          title: 'Details',
          action: AppSectionAction(
            label: 'Change',
            icon: AppIcons.pencil,
            onPressed: () {},
          ),
          children: [
            for (var i = 0; i < 6; i++)
              const StaffInfoRow(icon: AppIcons.phone, label: 'Phone', value: 'x'),
          ],
        ),
      ),
    );
    final real = _measure(tester);

    await tester.pumpWidget(
      _host(
        const PersonDetailSkeleton(
          pill: false,
          sections: [
            SkeletonSection(kind: SkeletonRow.info, rows: 6, action: true),
          ],
        ),
      ),
    );
    final card = tester.getSize(find.byType(AppCard).first).height;
    expect(card, real.card);
  });

  testWidgets('every row kind has the height of the real row', (tester) async {
    expect(SkeletonRow.info.height, StaffInfoRow.rowHeight);
    expect(SkeletonRow.access.height, StaffInfoRow.rowHeight);
    expect(SkeletonRow.person.height, 68);
    expect(SkeletonRow.action.height, 64);
  });

  testWidgets('with an action the header touches the card, without it 12', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PersonDetailSkeleton(
          pill: false,
          sections: [
            SkeletonSection(kind: SkeletonRow.info, rows: 2, action: true),
            SkeletonSection(kind: SkeletonRow.info, rows: 2),
          ],
        ),
      ),
    );
    final cards = find.byType(AppCard);
    expect(cards, findsNWidgets(2));
    // Section one: 44 header, no gap. Section two: 24 header, 12 gap.
    final firstBottom = tester.getBottomLeft(cards.at(0)).dy;
    final secondTop = tester.getTopLeft(cards.at(1)).dy;
    expect(secondTop - firstBottom, 24 + 24 + 12);
  });

  testWidgets('each page skeleton draws the cards its page has', (
    tester,
  ) async {
    Future<int> cards(Widget skeleton) async {
      await tester.pumpWidget(_host(skeleton));
      return find.byType(AppCard).evaluate().length;
    }

    // Staff: Teaching, Details, Personal, Access (+ its Actions card).
    expect(await cards(const StaffDetailSkeleton()), 5);
    // Student: Class, Parents, Details, Personal, Access (+ Actions).
    expect(await cards(const StudentDetailSkeleton()), 6);
    // A bursar's student page stops at Details.
    expect(await cards(const StudentDetailSkeleton(leader: false)), 3);
    // Parent: Children, Details, Access (+ Actions); no Access for others.
    expect(await cards(const ParentDetailSkeleton()), 4);
    expect(await cards(const ParentDetailSkeleton(leader: false)), 2);
  });
}
