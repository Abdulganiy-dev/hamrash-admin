import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 300, height: 100, child: child)),
    ),
  );

  Color colorOf(WidgetTester tester) =>
      tester.widget<ColoredBox>(find.byType(ColoredBox).last).color;

  testWidgets('is a 1px faint (stone-100) rule inset 16/16 by default', (
    tester,
  ) async {
    await pump(tester, const Align(child: AppDivider()));

    expect(colorOf(tester), AppPalette.stone100);
    expect(AppDivider.faint, AppPalette.stone100);
    final rect = tester.getRect(find.byType(AppDivider));
    expect(rect.height, 1);
    final line = tester.getRect(find.byType(ColoredBox).last);
    expect(line.left - rect.left, 16);
    expect(rect.right - line.right, 16);
  });

  testWidgets('onPage keeps stone-200', (tester) async {
    await pump(tester, const Align(child: AppDivider(onPage: true)));
    expect(colorOf(tester), AppPalette.stone200);
  });

  testWidgets('custom indents and the vertical rule', (tester) async {
    await pump(tester, const Align(child: AppDivider(indent: 72)));
    final rect = tester.getRect(find.byType(AppDivider));
    final line = tester.getRect(find.byType(ColoredBox).last);
    expect(line.left - rect.left, 72);

    await pump(
      tester,
      const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [AppDivider.vertical()],
      ),
    );
    final size = tester.getSize(find.byType(AppDivider));
    expect(size.width, 1);
    expect(size.height, 100);
    expect(colorOf(tester), AppPalette.stone100);
  });
}
