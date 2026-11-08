import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_invite_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _code = 'K7M2QX9P';
const _caption = 'Invite code · teacher';

Widget _host({String code = _code, String? caption}) => MaterialApp(
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: InviteCodeDisplay(code: code, caption: caption),
    ),
  ),
);

Finder _text(String text) => find.descendant(
  of: find.byType(InviteCodeDisplay),
  matching: find.text(text),
);

/// Anything that would paint a fill, tint, border or well behind the code.
final _paintedBackground = find.descendant(
  of: find.byType(InviteCodeDisplay),
  matching: find.byWidgetPredicate(
    (widget) => switch (widget) {
      Container(:final color, :final decoration) =>
        color != null || decoration != null,
      DecoratedBox(:final decoration) => decoration is BoxDecoration,
      ColoredBox() => true,
      _ => false,
    },
  ),
);

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(_text(text)).style!;

void main() {
  String? copied;
  late TestDefaultBinaryMessenger messenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    copied = null;
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('types the code as 4, a dash and 4 on one line', (tester) async {
    await tester.pumpWidget(_host());

    expect(_text('K7M2'), findsOneWidget);
    expect(_text('-'), findsOneWidget);
    expect(_text('QX9P'), findsOneWidget);

    final style = _styleOf(tester, 'K7M2');
    expect(style.fontSize, 40);
    expect(style.height, 46 / 40);
    expect(style.fontWeight, FontWeight.w800);
    expect(style.letterSpacing, 2.4);
    expect(style.color, LightColors.primaryPrimaryDefault);

    final dashStyle = _styleOf(tester, '-');
    expect(dashStyle.fontSize, 40);
    expect(dashStyle.fontWeight, FontWeight.w800);
    expect(dashStyle.letterSpacing, 2.4);
    expect(dashStyle.color, LightColors.textDisabled);

    // One line: the three parts share a centre line.
    final codeY = tester.getCenter(_text('K7M2')).dy;
    expect(tester.getCenter(_text('-')).dy, codeY);
    expect(tester.getCenter(_text('QX9P')).dy, codeY);

    // No per-character cells.
    for (final character in ['K', '7', 'M', '2', 'Q', 'X', '9', 'P']) {
      expect(
        _text(character),
        findsNothing,
        reason: '$character should be part of a group, not a cell',
      );
    }

    expect(_paintedBackground, findsNothing);
    expect(_text('Tap or long-press to copy'), findsOneWidget);
  });

  testWidgets('shows the optional label, uppercased and tracked', (
    tester,
  ) async {
    await tester.pumpWidget(_host(caption: _caption));

    expect(_text('INVITE CODE · TEACHER'), findsOneWidget);
    final label = _styleOf(tester, 'INVITE CODE · TEACHER');
    expect(label.fontSize, 12);
    expect(label.height, 16 / 12);
    expect(label.fontWeight, FontWeight.w700);
    expect(label.letterSpacing, 1.44);
    expect(label.color, LightColors.textBody);

    await tester.pumpWidget(_host());

    expect(_text('INVITE CODE · TEACHER'), findsNothing);
  });

  testWidgets('has no background behind the code, label or helper', (
    tester,
  ) async {
    await tester.pumpWidget(_host(caption: _caption));

    expect(_paintedBackground, findsNothing);
  });

  testWidgets('tapping copies the raw code without the dash', (tester) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.byType(InviteCodeDisplay));
    await tester.pump();

    expect(copied, _code);
    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('long-pressing copies too', (tester) async {
    await tester.pumpWidget(_host());

    await tester.longPress(find.byType(InviteCodeDisplay));
    await tester.pump();

    expect(copied, _code);
    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('a dashed code is copied raw', (tester) async {
    await tester.pumpWidget(_host(code: 'K7M2-QX9P'));

    await tester.tap(find.byType(InviteCodeDisplay));
    await tester.pump();

    expect(copied, _code);
    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('shows copied, then reverts after 1.6 seconds', (tester) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.byType(InviteCodeDisplay));
    await tester.pump();

    expect(find.text('Copied to clipboard'), findsOneWidget);
    expect(find.text('Tap or long-press to copy'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1599));
    expect(find.text('Copied to clipboard'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    expect(find.text('Copied to clipboard'), findsNothing);
    expect(find.text('Tap or long-press to copy'), findsOneWidget);
  });

  testWidgets('pressing recolours only the code groups', (tester) async {
    await tester.pumpWidget(_host(caption: _caption));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(InviteCodeDisplay)),
    );
    // The tap is only recognised as a press once the long-press has had its
    // chance to take it (kPressTimeout, 100ms).
    await tester.pump(const Duration(milliseconds: 150));

    expect(_styleOf(tester, 'K7M2').color, LightColors.primaryPrimaryPressed);
    expect(_styleOf(tester, 'QX9P').color, LightColors.primaryPrimaryPressed);
    expect(_styleOf(tester, '-').color, LightColors.textDisabled);
    expect(
      _styleOf(tester, 'INVITE CODE · TEACHER').color,
      LightColors.textBody,
    );
    expect(
      _styleOf(tester, 'Tap or long-press to copy').color,
      LightColors.textBody,
    );
    expect(_paintedBackground, findsNothing);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 1700));

    expect(_styleOf(tester, 'K7M2').color, LightColors.primaryPrimaryDefault);
  });

  testWidgets('announces the code one character at a time', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_host());

    expect(
      find.bySemanticsLabel('Invite code K 7 M 2 Q X 9 P'),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('scales down instead of overflowing a narrow block', (
    tester,
  ) async {
    Future<void> expectFits(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: InviteCodeDisplay(code: _code, caption: _caption),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      for (final text in ['INVITE CODE · TEACHER', 'K7M2', '-', 'QX9P']) {
        expect(
          tester.getTopLeft(_text(text)).dx,
          greaterThanOrEqualTo(0),
          reason: '$text starts inside $width',
        );
        expect(
          tester.getTopRight(_text(text)).dx,
          lessThanOrEqualTo(width + 0.01),
          reason: '$text ends inside $width',
        );
      }
      expect(
        tester.getSize(find.byType(InviteCodeDisplay)).width,
        lessThanOrEqualTo(width),
      );
    }

    await expectFits(240);
    await expectFits(342);
  });
}
