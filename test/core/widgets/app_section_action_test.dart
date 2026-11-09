import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

void main() {
  Widget host({VoidCallback? onPressed}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: AppSectionAction(
          label: 'Change',
          icon: AppIcons.pencil,
          semanticLabel: 'Change details',
          addBackground: true,
          onPressed: onPressed,
        ),
      ),
    ),
  );

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppSectionAction),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('renders the 32 pill inside a 44 tap box and fires', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(host(onPressed: () => taps++));

    expect(find.text('Change'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppSectionAction),
        matching: find.byType(AppIcon),
      ),
      findsOneWidget,
    );

    final size = tester.getSize(find.byType(AppSectionAction));
    expect(size.height, 44);
    expect(size.width, greaterThanOrEqualTo(44));

    final decoration = decorationOf(tester);
    expect(decoration.color, LightColors.primaryPrimaryMute);
    expect(decoration.borderRadius, BorderRadius.circular(999));
    expect(
      (decoration.border! as Border).top.color,
      LightColors.primaryPrimaryThin,
    );

    final text = tester.widget<Text>(find.text('Change'));
    expect(text.style?.fontSize, 14);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.color, LightColors.primaryPrimaryText);
    expect(text.style?.letterSpacing, 0);

    await tester.tap(find.byType(AppSectionAction));
    expect(taps, 1);
  });

  testWidgets('disabled greys out and does not take taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host());

    final decoration = decorationOf(tester);
    expect(decoration.color, AppPalette.stone100);
    expect((decoration.border! as Border).top.color, AppPalette.stone200);

    final text = tester.widget<Text>(find.text('Change'));
    expect(text.style?.color, LightColors.textDisabled);

    await tester.tap(find.byType(AppSectionAction));
    expect(taps, 0);
  });

  testWidgets('is built on the bouncy button and disabled when it is', (
    tester,
  ) async {
    await tester.pumpWidget(host(onPressed: () {}));
    expect(
      tester.widget<BouncyButton>(find.byType(BouncyButton)).isDisabled,
      isFalse,
    );

    await tester.pumpWidget(host());
    expect(
      tester.widget<BouncyButton>(find.byType(BouncyButton)).isDisabled,
      isTrue,
    );
  });

  testWidgets('icon and label sit on the same centre line', (tester) async {
    await tester.pumpWidget(host(onPressed: () {}));

    final icon = find.descendant(
      of: find.byType(AppSectionAction),
      matching: find.byType(AppIcon),
    );
    final label = find.descendant(
      of: find.byType(AppSectionAction),
      matching: find.text('Change'),
    );
    expect(
      (tester.getCenter(icon).dy - tester.getCenter(label).dy).abs(),
      lessThanOrEqualTo(0.5),
    );
  });

  testWidgets('semantics names the action', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(onPressed: () {}));
    expect(find.bySemanticsLabel('Change details'), findsOneWidget);
    handle.dispose();
  });
}
