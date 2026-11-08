import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/team/widgets/staff_filter_sheet.dart';

void main() {
  var result = 'untouched';
  StaffFilter? applied;

  Future<void> open(
    WidgetTester tester, {
    StaffFilter initial = StaffFilter.initial,
  }) async {
    // Tall, because test text is wide and the sheet would scroll.
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    result = 'untouched';
    applied = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                applied = await StaffFilterSheet.show(
                  context,
                  initial: initial,
                );
                result = applied == null ? 'closed' : 'applied';
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Color resetColor(WidgetTester tester) => tester
      .widget<AppText>(find.widgetWithText(AppText, 'Reset'))
      .style!
      .color!;

  bool isSelected(WidgetTester tester, String label) => tester
      .widget<AppFilterChip>(find.widgetWithText(AppFilterChip, label))
      .selected;

  testWidgets('lays out the sections of 8.17', (tester) async {
    await open(tester);

    expect(find.text('Filter staff'), findsOneWidget);
    expect(find.byType(AppSearchField), findsOneWidget);
    expect(find.text('Search by name, phone or staff number'), findsOneWidget);
    for (final section in ['Login', 'Role', 'Staff type', 'Status', 'Sort by']) {
      expect(find.text(section), findsOneWidget);
    }
    for (final label in [
      'Code ready',
      'Suspended',
      'Owner',
      'Vice principal',
      'Bursar',
      'Active',
      'On leave',
      'Exited',
      'Name A–Z',
      'Newest first',
    ]) {
      expect(find.widgetWithText(AppFilterChip, label), findsOneWidget);
    }
    expect(find.byType(AppSegmentedControl<StaffTypeFilter>), findsOneWidget);
    expect(find.text('Non-teaching'), findsOneWidget);

    // Active and Name A–Z are the ticked defaults.
    expect(isSelected(tester, 'Active'), isTrue);
    expect(isSelected(tester, 'Name A–Z'), isTrue);
    // A plain, always-enabled button: no count, no request.
    expect(find.text('Show results'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.byType(AppButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Reset is greyed out until the draft changes', (tester) async {
    await open(tester);
    expect(resetColor(tester), LightColors.textDisabled);

    await tester.tap(find.text('Teacher'));
    await tester.pump();
    expect(resetColor(tester), LightColors.primaryPrimaryText);
  });

  testWidgets('Reset puts the draft back to defaults, search included', (
    tester,
  ) async {
    await open(
      tester,
      initial: const StaffFilter(
        search: 'ada',
        roles: {OrganizationMemberRole.teacher},
        sort: StaffSort.newest,
      ),
    );
    expect(find.text('ada'), findsOneWidget);
    expect(resetColor(tester), LightColors.primaryPrimaryText);

    await tester.tap(find.text('Reset'));
    await tester.pump();

    expect(find.text('ada'), findsNothing);
    expect(resetColor(tester), LightColors.textDisabled);
    expect(isSelected(tester, 'Teacher'), isFalse);
    expect(isSelected(tester, 'Name A–Z'), isTrue);
    // Reset only edits the draft; the sheet stays open.
    expect(result, 'untouched');
    expect(find.text('Filter staff'), findsOneWidget);
  });

  testWidgets('Show results applies the draft and closes', (tester) async {
    await open(tester);

    await tester.tap(find.text('Teacher'));
    await tester.tap(find.text('Newest first'));
    await tester.tap(find.text('Teaching'));
    await tester.tap(find.text('On leave'));
    await tester.enterText(find.byType(TextField), 'ada');
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    expect(result, 'applied');
    expect(applied!.roles, {OrganizationMemberRole.teacher});
    expect(applied!.sort, StaffSort.newest);
    expect(applied!.staffType, StaffTypeFilter.teaching);
    expect(applied!.search, 'ada');
    expect(applied!.statuses, {
      StaffRecordStatus.active,
      StaffRecordStatus.onLeave,
    });
    expect(find.text('Filter staff'), findsNothing);
  });

  testWidgets('closing throws the draft away', (tester) async {
    await open(tester);

    await tester.tap(find.text('Teacher'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();

    expect(result, 'closed');
    expect(applied, isNull);
    expect(find.text('Filter staff'), findsNothing);
  });

  testWidgets('a status can be ticked off, leaving every status', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Active'));
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    expect(applied!.statuses, isEmpty);
  });
}
