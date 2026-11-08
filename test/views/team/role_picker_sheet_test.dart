import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:hamrash_admin/views/team/widgets/role_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({
  OrganizationMemberRole selected = OrganizationMemberRole.teacher,
  bool lockAdmin = false,
}) => MaterialApp(
  home: Scaffold(
    backgroundColor: AppPalette.white,
    body: RolePickerSheet(selected: selected, lockAdmin: lockAdmin),
  ),
);

Finder _row(OrganizationMemberRole role) =>
    find.byKey(ValueKey('role-row-${role.value}'));

List<Container> _containers(WidgetTester tester, Finder row) => tester
    .widgetList<Container>(
      find.descendant(of: row, matching: find.byType(Container)),
    )
    .toList();

/// The radio: the only round container in a row.
List<Container> _circles(WidgetTester tester, Finder row) =>
    _containers(tester, row)
        .where((container) => _decoration(container).shape == BoxShape.circle)
        .toList();

bool _paintsBackground(Widget widget) {
  if (widget is ColoredBox) return widget.color.a > 0;
  if (widget is DecoratedBox) return true;
  if (widget is Container) {
    final decoration = widget.decoration;
    if (decoration is! BoxDecoration) return false;
    return (decoration.color?.a ?? 0) > 0 ||
        decoration.border != null ||
        decoration.boxShadow != null;
  }
  return false;
}

/// The white check inside the radio, scaled in only when picked.
double _checkScale(WidgetTester tester, Finder row) => tester
    .widget<AnimatedScale>(
      find.descendant(of: row, matching: find.byType(AnimatedScale)),
    )
    .scale;

BoxDecoration _decoration(Container container) =>
    container.decoration! as BoxDecoration;

AppText _title(WidgetTester tester, OrganizationMemberRole role) => tester
    .widgetList<AppText>(
      find.descendant(of: _row(role), matching: find.byType(AppText)),
    )
    .first;

Finder _icon(AppSvgIconData icon, Finder row) => find.descendant(
  of: row,
  matching: find.byWidgetPredicate(
    (widget) => widget is AppSvgIcon && widget.icon == icon,
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('rows sit on the white sheet with no fill or radius', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.byType(AppRowGroup), findsNothing);

    for (final role in RolePickerSheet.roles) {
      expect(
        tester.widgetList(
          find.ancestor(
            of: find.text(role.teamLabel),
            matching: find.byWidgetPredicate(_paintsBackground),
          ),
        ),
        isEmpty,
        reason: '${role.teamLabel} must sit straight on the sheet',
      );
      expect(
        _circles(tester, _row(role)),
        hasLength(1),
        reason: '${role.teamLabel} shows only its radio, with no row fill',
      );
    }
  });

  testWidgets('the picked row is a filled aubergine circle with a check', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    final picked = _decoration(
      _circles(tester, _row(OrganizationMemberRole.teacher)).single,
    );
    expect(picked.color, LightColors.primaryPrimaryDefault);
    expect(
      (picked.border! as Border).top.color,
      LightColors.primaryPrimaryDefault,
    );
    expect(
      _icon(AppSvgIcons.check600, _row(OrganizationMemberRole.teacher)),
      findsOneWidget,
    );
    expect(_checkScale(tester, _row(OrganizationMemberRole.teacher)), 1);

    final empty = _decoration(
      _circles(tester, _row(OrganizationMemberRole.staff)).single,
    );
    expect(empty.color, AppPalette.white);
    expect((empty.border! as Border).top.color, AppPalette.stone300);
    expect(
      _icon(AppSvgIcons.check600, _row(OrganizationMemberRole.staff)),
      findsOneWidget,
    );
    expect(_checkScale(tester, _row(OrganizationMemberRole.staff)), 0);
  });

  testWidgets('the picked title is 800, the others 700', (tester) async {
    await tester.pumpWidget(_host());

    expect(
      _title(tester, OrganizationMemberRole.teacher).style?.fontWeight,
      FontWeight.w800,
    );
    expect(
      _title(tester, OrganizationMemberRole.staff).style?.fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('rows are 66 tall with 4 between them', (tester) async {
    await tester.pumpWidget(_host());

    expect(tester.getSize(_row(OrganizationMemberRole.admin)).height, 66);

    final rows = [for (final role in RolePickerSheet.roles) _row(role)];
    for (var i = 1; i < rows.length; i++) {
      expect(
        tester.getTopLeft(rows[i]).dy - tester.getBottomLeft(rows[i - 1]).dy,
        4,
      );
    }
  });

  testWidgets('a locked admin row cannot be picked', (tester) async {
    await tester.pumpWidget(_host(lockAdmin: true));

    expect(
      find.text('Only the owner or an admin can invite admins'),
      findsOneWidget,
    );
    expect(find.text('Use Teacher'), findsOneWidget);

    final admin = _row(OrganizationMemberRole.admin);
    expect(_circles(tester, admin), isEmpty);
    expect(_icon(AppSvgIcons.lock, admin), findsOneWidget);

    await tester.tap(admin);
    await tester.pumpAndSettle();

    expect(find.text('Use Teacher'), findsOneWidget);
  });
}
