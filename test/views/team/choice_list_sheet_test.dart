import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';

void main() {
  Future<String?> open(
    WidgetTester tester, {
    required List<String> items,
    String? selected,
  }) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await ChoiceListSheet.show<String>(
                  context: context,
                  title: 'Choose a state',
                  subtitle: 'For Chinedu Obi',
                  searchHint: 'Search states',
                  items: items,
                  labelBuilder: (value) => value,
                  selected: selected,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('search filters and a row returns its value', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await ChoiceListSheet.show<String>(
                  context: context,
                  title: 'Choose a state',
                  subtitle: 'For Chinedu Obi',
                  searchHint: 'Search states',
                  items: const ['Kano', 'Lagos', 'Oyo'],
                  labelBuilder: (value) => value,
                  selected: 'Lagos',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a state'), findsOneWidget);
    expect(find.text('For Chinedu Obi'), findsOneWidget);
    expect(find.text('Search states'), findsOneWidget);
    expect(find.text('Kano'), findsOneWidget);
    expect(find.text('Lagos'), findsOneWidget);
    expect(find.text('Oyo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'oy');
    await tester.pumpAndSettle();

    expect(find.text('Kano'), findsNothing);
    expect(find.text('Oyo'), findsOneWidget);
    await tester.tap(find.text('Oyo'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a state'), findsNothing);
    expect(result, 'Oyo');
  });

  testWidgets('the selected row is scrolled into view', (tester) async {
    final items = [for (var i = 0; i < 50; i++) 'LGA $i'];
    await open(tester, items: items, selected: 'LGA 40');

    expect(find.text('LGA 40'), findsOneWidget);
  });

  testWidgets('a search that matches nothing says so', (tester) async {
    await open(tester, items: const ['Kano', 'Lagos', 'Oyo']);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No results for “zzz”'), findsOneWidget);
    expect(find.text('Check the spelling and try again.'), findsOneWidget);
    expect(find.text('Kano'), findsNothing);
    // The search stays, so the query can be fixed.
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kan');
    await tester.pumpAndSettle();
    expect(find.text('Kano'), findsOneWidget);
    expect(find.text('No results for “kan”'), findsNothing);
  });

  testWidgets('an empty list says what is missing and has no search', (
    tester,
  ) async {
    await open(tester, items: const []);

    expect(find.text('Nothing to choose yet'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
