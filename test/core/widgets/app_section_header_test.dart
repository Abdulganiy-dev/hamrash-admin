import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

void main() {
  Widget host(Widget header) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 390,
          child: Column(mainAxisSize: MainAxisSize.min, children: [header]),
        ),
      ),
    ),
  );

  testWidgets(
    'with an action the row is 44 tall and the action is flush right',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          AppSectionHeader(
            title: 'Primary',
            caption: '3 classes',
            action: AppSectionAction(
              label: 'Edit',
              icon: AppIcons.pencil,
              semanticLabel: 'Edit Primary',
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      final header = find.byType(AppSectionHeader);
      final action = find.byType(AppSectionAction);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('3 classes'), findsOneWidget);
      expect(tester.getSize(header).height, 44);
      expect(tester.getSize(action).height, 44);
      expect(
        tester.getTopRight(action).dx,
        closeTo(tester.getTopRight(header).dx - AppSpacing.xs, 0.5),
      );

      await tester.tap(action);
      expect(taps, 1);
    },
  );

  testWidgets('without an action the header keeps its compact row', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppSectionHeader(title: 'Optional', caption: '2 subjects')),
    );

    expect(find.byType(AppSectionAction), findsNothing);
    expect(tester.getSize(find.byType(AppSectionHeader)).height, lessThan(44));
  });

  testWidgets('trailing still takes a non-action widget', (tester) async {
    await tester.pumpWidget(
      host(
        const AppSectionHeader(
          title: 'Other sessions',
          trailing: AppText('2 sessions'),
        ),
      ),
    );

    expect(find.text('2 sessions'), findsOneWidget);
    expect(find.byType(AppSectionAction), findsNothing);
  });
}
