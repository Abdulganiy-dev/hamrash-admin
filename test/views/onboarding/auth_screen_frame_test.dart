import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';

void main() {
  testWidgets('Done replaces the footer and closes the keyboard', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreenFrame(
          showBackButton: false,
          scrollContent: TextField(keyboardType: TextInputType.phone),
          footer: Text('Join school'),
        ),
      ),
    );
    expect(find.text('Join school'), findsOneWidget);
    expect(find.text('Done'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    final fieldFocus = tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode;
    expect(fieldFocus.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    // Both are on screen while they cross-fade.
    expect(find.text('Join school'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Join school'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    final keyboardTop =
        (tester.view.physicalSize.height - tester.view.viewInsets.bottom) /
        tester.view.devicePixelRatio;
    expect(tester.getBottomLeft(find.text('Done')).dy, lessThan(keyboardTop));

    await tester.tap(
      find.ancestor(
        of: find.text('Done'),
        matching: find.byType(AppTertiaryButton),
      ),
    );
    await tester.pump();
    expect(fieldFocus.hasFocus, isFalse);

    // Keyboard goes down: the footer fades back in.
    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Done'), findsNothing);
    expect(find.text('Join school'), findsOneWidget);
  });
}
