import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/views/classes/widgets/section_card.dart';

void main() {
  const section = SchoolSection(
    id: 'section-1',
    name: 'Primary',
    sortOrder: 1,
    isActive: true,
    classes: [
      SchoolClass(
        id: 'class-1',
        sectionId: 'section-1',
        name: 'Primary 1',
        sortOrder: 1,
        isGraduating: false,
        isActive: true,
        arms: [],
      ),
    ],
  );

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 390,
          child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
        ),
      ),
    ),
  );

  testWidgets('Edit is a section action and fires', (tester) async {
    final semantics = tester.ensureSemantics();
    var edits = 0;
    await tester.pumpWidget(
      host(SectionCard(section: section, onEdit: () => edits++)),
    );

    final action = find.byType(AppSectionAction);
    expect(action, findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit Primary'), findsOneWidget);

    await tester.tap(action);
    expect(edits, 1);
    semantics.dispose();
  });

  testWidgets('no Edit action without permission to change classes', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SectionCard(section: section)));

    expect(find.byType(AppSectionAction), findsNothing);
    expect(find.text('Edit'), findsNothing);
  });
}
