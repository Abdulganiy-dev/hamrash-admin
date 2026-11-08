import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';

void main() {
  const surfaceKey = ValueKey('bottom-bar-surface');
  const fadeKey = ValueKey('bottom-bar-fade');

  Widget host() => MaterialApp(
    home: DefaultScaffold(
      backgroundColor: AppPalette.linen,
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) =>
            SizedBox(height: 80, child: Text('Row $index')),
      ),
      bottomNavigationBar: const SizedBox(
        height: 56,
        child: Center(child: Text('Footer')),
      ),
    ),
  );

  testWidgets('a bottom bar sits on an opaque surface', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final surface = find.byKey(surfaceKey);
    expect(surface, findsOneWidget);
    expect(tester.widget<ColoredBox>(surface).color, AppPalette.linen);
    expect(tester.getSize(surface).height, 56);
    expect(tester.getBottomLeft(surface).dy, 600);
  });

  testWidgets('a bottom bar gets the full screen width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // The footer's own Center would shrink to "Footer" if the surface
    // loosened the width it passes down.
    expect(tester.getSize(find.byKey(surfaceKey)).width, 390);
    expect(tester.getSize(find.byKey(surfaceKey)).height, 56);
    expect(tester.getCenter(find.text('Footer')).dx, closeTo(195, 0.5));
  });

  testWidgets('a 16px fade above the bar ignores pointers', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final fade = find.byKey(fadeKey);
    expect(fade, findsOneWidget);
    expect(tester.widget<IgnorePointer>(fade).ignoring, isTrue);
    expect(tester.getSize(fade).height, 16);

    final gradient = tester
        .widget<DecoratedBox>(
          find.descendant(of: fade, matching: find.byType(DecoratedBox)),
        )
        .decoration;
    final linear = (gradient as BoxDecoration).gradient! as LinearGradient;
    expect(linear.begin, Alignment.topCenter);
    expect(linear.end, Alignment.bottomCenter);
    expect(linear.colors, [
      AppPalette.linen.withValues(alpha: 0),
      AppPalette.linen,
    ]);

    final barTop = tester.getTopLeft(find.byKey(surfaceKey)).dy;
    expect(tester.getBottomLeft(fade).dy, closeTo(barTop, 0.01));
  });

  testWidgets('the scrolling body ends above the bar', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final barTop = tester.getTopLeft(find.byKey(surfaceKey)).dy;
    final scrollBottom = tester.getBottomLeft(find.byType(Scrollable)).dy;
    expect(scrollBottom, lessThanOrEqualTo(barTop));

    await tester.scrollUntilVisible(
      find.text('Row 99'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Row 99'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Row 99')).dy,
      lessThanOrEqualTo(barTop),
    );
  });
}
