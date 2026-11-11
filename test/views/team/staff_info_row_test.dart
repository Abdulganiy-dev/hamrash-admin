import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_rows.dart';

void main() {
  Widget host(StaffInfoRow row) => MaterialApp(
    home: Scaffold(body: Center(child: row)),
  );

  testWidgets('icon, label and value share one centre line', (tester) async {
    await tester.pumpWidget(
      host(
        const StaffInfoRow(
          icon: AppIcons.phone,
          label: 'Phone',
          value: '0803 555 0142',
        ),
      ),
    );

    final icon = tester.getCenter(find.byType(AppIcon)).dy;
    final label = tester.getCenter(find.text('Phone')).dy;
    final value = tester.getCenter(find.text('0803 555 0142')).dy;
    expect((icon - label).abs(), lessThanOrEqualTo(0.5));
    expect((label - value).abs(), lessThanOrEqualTo(0.5));
    expect(tester.getSize(find.byType(StaffInfoRow)).height, 52);
  });

  testWidgets('a multi-line value keeps icon and label on its first line', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const StaffInfoRow(
          icon: AppIcons.house,
          label: 'Home address',
          value: '22 Ogunlana Drive, Surulere, Lagos Mainland, Lagos State',
          multiline: true,
        ),
      ),
    );

    final icon = tester.getCenter(find.byType(AppIcon)).dy;
    final label = tester.getCenter(find.text('Home address')).dy;
    expect((icon - label).abs(), lessThanOrEqualTo(0.5));
    expect(tester.getSize(find.byType(StaffInfoRow)).height, greaterThan(52));
  });

  testWidgets('an empty value reads "Not added" in the disabled colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const StaffInfoRow(icon: AppIcons.mail, label: 'Email', value: ' '),
      ),
    );

    final value = tester.widget<Text>(find.text('Not added'));
    expect(value.style?.color, LightColors.textDisabled);
    expect(value.style?.fontWeight, FontWeight.w600);
    expect(value.style?.fontSize, 15);
  });
}
