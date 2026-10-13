import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_keyboard_bar.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({required List<FocusNode> nodes, required Widget bar}) =>
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [for (final node in nodes) TextField(focusNode: node)],
        ),
        bottomNavigationBar: bar,
      ),
    );

/// The text sits under the button's IgnorePointer, so tap the button.
final _doneButton = find.ancestor(
  of: find.text('Done'),
  matching: find.byType(AppTertiaryButton),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Done hides the keyboard and calls onDone', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var done = 0;

    await tester.pumpWidget(
      _host(
        nodes: [node],
        bar: AppKeyboardBar(onDone: () => done++),
      ),
    );
    node.requestFocus();
    await tester.pump();

    await tester.tap(_doneButton);
    await tester.pump();
    expect(node.hasFocus, isFalse);
    expect(done, 1);
  });

  testWidgets('no arrows under three fields', (tester) async {
    await tester.pumpWidget(
      _host(nodes: [], bar: const AppKeyboardBar(fieldIndex: 0, fieldCount: 2)),
    );
    expect(find.bySemanticsLabel('Next field'), findsNothing);
    expect(find.text('1 of 2'), findsNothing);
  });

  testWidgets('arrows step focus and fade at the ends', (tester) async {
    final nodes = List.generate(3, (_) => FocusNode());
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });

    Future<void> pumpAt(int index) => tester.pumpWidget(
      _host(
        nodes: nodes,
        bar: AppKeyboardBar(fieldIndex: index, fieldCount: nodes.length),
      ),
    );

    await pumpAt(0);
    nodes[0].requestFocus();
    await tester.pump();
    expect(find.text('1 of 3'), findsOneWidget);

    // Up does nothing on the first field.
    await tester.tap(find.bySemanticsLabel('Previous field'));
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel('Next field'));
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);

    await pumpAt(2);
    nodes[2].requestFocus();
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Next field'));
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel('Previous field'));
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);
  });

  testWidgets('action bar keeps the button and a dismiss square', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var pressed = 0;

    await tester.pumpWidget(
      _host(
        nodes: [node],
        bar: AppKeyboardBar.action(
          action: ElevatedButton(
            onPressed: () => pressed++,
            child: const Text('Continue'),
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();

    await tester.tap(find.text('Continue'));
    expect(pressed, 1);
    expect(node.hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel('Hide keyboard'));
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });

  testWidgets('sits above the keyboard', (tester) async {
    addTearDown(tester.view.resetViewInsets);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);

    await tester.pumpWidget(_host(nodes: [], bar: const AppKeyboardBar()));

    final keyboardTop =
        (tester.view.physicalSize.height - tester.view.viewInsets.bottom) /
        tester.view.devicePixelRatio;
    final doneBottom = tester.getBottomLeft(find.text('Done')).dy;
    expect(doneBottom, lessThan(keyboardTop));
    expect(doneBottom, greaterThan(keyboardTop - AppKeyboardBar.height));
  });
}
