import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_spring_pager.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_bar.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_shell.dart';

void main() {
  testWidgets('four tab slots fit a narrow navigation area', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 280,
            child: AppTabBar(
              items: const [
                AppTabItem(icon: AppSvgIcons.house, label: 'Home'),
                AppTabItem(icon: AppSvgIcons.users, label: 'People'),
                AppTabItem(icon: AppSvgIcons.wallet, label: 'Fees'),
                AppTabItem(icon: AppSvgIcons.layoutGrid, label: 'More'),
              ],
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AppSvgIcon), findsNWidgets(4));
  });

  testWidgets('tab jumps slide directly and retain edited page state', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppTabShell(
          tabs: [
            AppTab(
              item: const AppTabItem(icon: AppSvgIcons.house, label: 'Home'),
              builder: (_) => const Scaffold(body: TextField()),
            ),
            AppTab(
              item: const AppTabItem(icon: AppSvgIcons.users, label: 'People'),
              builder: (_) {
                builds++;
                return const Scaffold(body: Text('People page'));
              },
            ),
            AppTab(
              item: const AppTabItem(
                icon: AppSvgIcons.layoutGrid,
                label: 'More',
              ),
              builder: (_) => const Scaffold(body: Text('More page')),
            ),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    var bar = tester.widget<AppTabBar>(find.byType(AppTabBar));
    bar.onTap(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(AppSpringPager), findsOneWidget);
    expect(find.text('More page'), findsOneWidget);
    expect(
      builds,
      0,
      reason: 'A direct jump must not build intermediate tabs.',
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    bar = tester.widget<AppTabBar>(find.byType(AppTabBar));
    bar.onTap(0);
    await tester.pumpAndSettle();
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(builds, 0);
  });

  for (final direction in TextDirection.values) {
    testWidgets('the shared dot slides to the selected tab in $direction', (
      tester,
    ) async {
      var index = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return AppTabBar(
                    items: const [
                      AppTabItem(icon: AppSvgIcons.house, label: 'Home'),
                      AppTabItem(icon: AppSvgIcons.users, label: 'People'),
                      AppTabItem(icon: AppSvgIcons.layoutGrid, label: 'More'),
                    ],
                    currentIndex: index,
                    onTap: (_) {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      final dot = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      final start = tester.getCenter(dot).dx;
      update(() => index = 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final during = tester.getCenter(dot).dx;
      await tester.pumpAndSettle();
      final end = tester.getCenter(dot).dx;
      expect(during, isNot(start));
      expect(during, isNot(end));
      expect(
        end - start,
        closeTo(direction == TextDirection.ltr ? 160 : -160, 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
