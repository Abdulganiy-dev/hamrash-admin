import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/views/team/widgets/staff_list_card.dart';

StaffTeaching _t(String subject, String cls, String arm) => StaffTeaching(
  subjectId: subject,
  subjectName: subject,
  armId: '$cls$arm',
  armName: arm,
  classId: cls,
  className: cls,
);

StaffMember _person(String id, String first, List<StaffTeaching>? teaching) =>
    StaffMember(
      id: id,
      firstName: first,
      lastName: 'Teacher',
      jobTitle: 'Teacher',
      staffType: 'teaching',
      status: StaffRecordStatus.active,
      createdAt: DateTime(2026, 11, 8),
      teaching: teaching,
    );

void main() {
  testWidgets(
    'a subject filter shows each teacher with the classes they teach it in',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StaffListCard(
                staff: [
                  _person('1', 'John', [
                    _t('Mathematics', 'JSS 1', 'A'),
                    _t('Mathematics', 'JSS 2', 'A'),
                    _t('Mathematics', 'SSS 1', 'B'),
                  ]),
                  _person('2', 'Jane', [_t('Mathematics', 'JSS 3', 'A')]),
                  _person('3', 'Both', [
                    _t('Art', 'JSS 1', 'A'),
                    _t('Mathematics', 'JSS 1', 'B'),
                  ]),
                  _person('4', 'Plain', null),
                  _person('5', 'Empty', const []),
                ],
                subtitleFor: (person) => 'Teacher',
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      );

      String text(String first) => (find
          .descendant(
            of: find
                .ancestor(
                  of: find.text('$first Teacher'),
                  matching: find.byType(Column),
                )
                .first,
            matching: find.byType(RichText),
          )
          .evaluate()
          .map((e) => (e.widget as RichText).text.toPlainText())
          .where((t) => t.contains('·') && !t.contains('Teacher'))
          .join('|'));

      expect(text('John'), 'Mathematics · JSS 1A, JSS 2A, SSS 1B');
      expect(text('Jane'), 'Mathematics · JSS 3A');
      // One teacher, two subjects: a line for each, never merged.
      expect(text('Both'), 'Art · JSS 1A|Mathematics · JSS 1B');
      // No filter, or no matching assignment: nothing extra.
      expect(text('Plain'), '');
      expect(text('Empty'), '');
    },
  );
}
