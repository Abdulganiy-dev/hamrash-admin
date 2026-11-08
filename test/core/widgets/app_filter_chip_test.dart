import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_chip_row.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

/// The 40 tall visual inside the 48 tall tap area: the only decorated
/// container in the chip.
final _visualFinder = find.descendant(
  of: find.byType(AppFilterChip),
  matching: find.byWidgetPredicate(
    (widget) => widget is Container && widget.decoration is BoxDecoration,
  ),
);

Container _visual(WidgetTester tester) =>
    tester.widget<Container>(_visualFinder);

BoxDecoration _decoration(WidgetTester tester) =>
    _visual(tester).decoration! as BoxDecoration;

Color _fill(WidgetTester tester) => _decoration(tester).color!;

Color _border(WidgetTester tester) =>
    (_decoration(tester).border! as Border).top.color;

/// The label and count share one text run: [label, " · count"].
List<TextSpan> _spans(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byType(AppFilterChip),
      matching: find.byType(Text),
    ),
  );
  return (text.textSpan! as TextSpan).children!.cast<TextSpan>();
}

Color? _labelColor(WidgetTester tester) => _spans(tester).first.style?.color;

Color? _countColor(WidgetTester tester) => _spans(tester).last.style?.color;

List<AppIcon> _iconWidgets(WidgetTester tester) =>
    tester
        .widgetList<AppIcon>(
          find.descendant(
            of: find.byType(AppFilterChip),
            matching: find.byType(AppIcon),
          ),
        )
        .toList();

List<IconData?> _icons(WidgetTester tester) =>
    _iconWidgets(tester).map((icon) => icon.icon).toList();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('default is a white pill with a muted border', (tester) async {
    await tester.pumpWidget(_host(const AppFilterChip(label: 'All')));

    expect(_fill(tester), AppPalette.white);
    expect(_border(tester), LightColors.textMuted);
    expect(_labelColor(tester), LightColors.textStrong);
    expect(_icons(tester), isEmpty);
  });

  testWidgets('selected is a light aubergine tint with aubergine text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppFilterChip(label: 'All', selected: true)),
    );

    expect(_fill(tester), LightColors.primaryPrimaryMute);
    expect(_border(tester), LightColors.primaryPrimaryDefault);
    expect(_labelColor(tester), LightColors.primaryPrimaryText);
    expect(_icons(tester), isEmpty, reason: 'selected chips show no check');
  });

  testWidgets('selected chip is flat, with 16 side padding and no check', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppFilterChip(label: 'All', selected: true)),
    );

    expect(_decoration(tester).gradient, isNull);
    expect(_visual(tester).padding, const EdgeInsets.symmetric(horizontal: 16));
    expect(_icons(tester), isEmpty);
  });

  testWidgets('disabled is a flat stone pill with disabled text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppFilterChip(label: 'All', enabled: false)),
    );

    expect(_fill(tester), AppPalette.stone100);
    expect(_border(tester), AppPalette.stone200);
    expect(_labelColor(tester), LightColors.textDisabled);
  });

  testWidgets('pressing an unselected chip steps to the surface layer', (
    tester,
  ) async {
    await tester.pumpWidget(_host(AppFilterChip(label: 'All', onTap: () {})));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppFilterChip)),
    );
    await tester.pump();

    expect(_fill(tester), AppPalette.stone100);
    expect(_border(tester), LightColors.textMuted);

    await gesture.up();
    await tester.pump();

    expect(_fill(tester), AppPalette.white);
  });

  testWidgets('state changes apply on the next frame, with no animation', (
    tester,
  ) async {
    await tester.pumpWidget(_host(AppFilterChip(label: 'All', onTap: () {})));

    expect(
      find.descendant(
        of: find.byType(AppFilterChip),
        matching: find.byWidgetPredicate((w) => w is ImplicitlyAnimatedWidget),
      ),
      findsNothing,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppFilterChip)),
    );
    await tester.pump();
    expect(_fill(tester), AppPalette.stone100);

    await gesture.up();
    await tester.pump();
    expect(_fill(tester), AppPalette.white);
  });

  testWidgets('pressing a selected chip steps to aubergine-100', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(AppFilterChip(label: 'All', selected: true, onTap: () {})),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppFilterChip)),
    );
    await tester.pump();

    expect(_fill(tester), AppPalette.aubergine100);
    expect(_border(tester), LightColors.primaryPrimaryDefault);
    expect(_labelColor(tester), LightColors.primaryPrimaryText);

    await gesture.up();
    await tester.pump();
    expect(_fill(tester), LightColors.primaryPrimaryMute);
  });

  testWidgets('keeps a 48 tall tap target around a 40 tall pill', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const AppFilterChip(label: 'A')));

    expect(tester.getSize(find.byType(AppFilterChip)).height, 48);
    expect(
      tester.getSize(find.byType(AppFilterChip)).width,
      greaterThanOrEqualTo(48),
    );
    expect(tester.getSize(_visualFinder).height, 40);
    expect(tester.getSize(_visualFinder).width, greaterThanOrEqualTo(48));
  });

  testWidgets('renders the count inline, in its own colour', (tester) async {
    await tester.pumpWidget(
      _host(const AppFilterChip(label: 'On app', count: 3)),
    );

    final spans = _spans(tester);
    expect(spans, hasLength(2));
    expect(spans.first.text, 'On app');
    expect(spans.last.text, ' · 3');
    expect(_countColor(tester), LightColors.textBody);
    expect(_labelColor(tester), LightColors.textStrong);
    expect(find.byType(AppCountBadge), findsNothing);
  });

  testWidgets('count on a selected chip is aubergine-400', (tester) async {
    await tester.pumpWidget(
      _host(const AppFilterChip(label: 'All', count: 12, selected: true)),
    );

    expect(_countColor(tester), AppPalette.aubergine400);
    expect(_labelColor(tester), LightColors.primaryPrimaryText);
  });

  testWidgets('a removable chip shows an aubergine × and no check', (
    tester,
  ) async {
    var removed = 0;
    await tester.pumpWidget(
      _host(
        AppFilterChip(
          label: 'Term 2',
          selected: true,
          onRemove: () => removed++,
        ),
      ),
    );

    expect(_icons(tester), [AppIcons.x]);
    expect(_iconWidgets(tester).single.color, LightColors.primaryPrimaryText);

    await tester.tap(find.byType(AppIcon));
    expect(removed, 1);
  });

  testWidgets('a locked chip shows an aubergine lock and stays tappable', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      _host(
        AppFilterChip(
          label: 'Primary 1A',
          selected: true,
          locked: true,
          onTap: () => tapped++,
        ),
      ),
    );

    expect(_icons(tester), [AppIcons.lock]);
    expect(_iconWidgets(tester).single.color, LightColors.primaryPrimaryText);
    expect(_fill(tester), LightColors.primaryPrimaryMute);
    expect(_border(tester), LightColors.primaryPrimaryDefault);

    await tester.tap(find.byType(AppFilterChip));
    expect(tapped, 1);
  });

  testWidgets('a suggestion chip leads with the plus', (tester) async {
    await tester.pumpWidget(
      _host(AppFilterChip(label: 'Gold', suggestion: true, onTap: () {})),
    );

    expect(_icons(tester), [AppIcons.plus]);
    expect(_fill(tester), AppPalette.white);
    expect(_border(tester), LightColors.textMuted);
  });

  testWidgets('tap fires onTap and is off when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(AppFilterChip(label: 'All', onTap: () => taps++)),
    );

    await tester.tap(find.byType(AppFilterChip));
    expect(taps, 1);

    await tester.pumpWidget(
      _host(AppFilterChip(label: 'All', enabled: false, onTap: () => taps++)),
    );
    await tester.tap(find.byType(AppFilterChip));
    expect(taps, 1);
  });

  testWidgets('AppChipRow keeps the chips in one scrolling row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 220,
          child: AppChipRow(
            children: [
              AppFilterChip(label: 'All', onTap: () {}),
              AppFilterChip(label: 'On app', onTap: () {}),
              AppFilterChip(label: 'Not on app', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    final chips = find.byType(AppFilterChip);
    expect(chips, findsNWidgets(3));
    final tops = <double>{
      for (var i = 0; i < 3; i++) tester.getTopLeft(chips.at(i)).dy,
    };
    expect(tops, hasLength(1), reason: 'the chips must not wrap');

    final row = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(row.scrollDirection, Axis.horizontal);
  });
}
