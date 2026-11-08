import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
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

  testWidgets('an action makes a 44 tall header with the action flush right', (
    tester,
  ) async {
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
    expect(tester.getSize(header).height, 44);
    expect(tester.getSize(action).height, 44);
    expect(
      tester.getTopRight(action).dx,
      closeTo(tester.getTopRight(header).dx, 0.5),
    );

    await tester.tap(action);
    expect(taps, 1);
  });

  testWidgets('a caption keeps the 32 tall header', (tester) async {
    await tester.pumpWidget(
      host(
        const StaffInfoSection(
          title: 'Personal',
          trailing: AppText('LEADER ONLY'),
          rows: [],
        ),
      ),
    );

    expect(find.text('LEADER ONLY'), findsOneWidget);
    expect(find.byType(AppSectionAction), findsNothing);
    expect(tester.getSize(find.byType(StaffInfoSection)).height, 32);
  });
}
