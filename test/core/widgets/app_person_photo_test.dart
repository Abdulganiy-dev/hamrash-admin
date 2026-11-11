import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_person_photo.dart';
import 'package:hamrash_admin/core/widgets/image_view.dart';

Widget _host(String? url) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: AppPersonPhoto(url: url, size: 40, fallback: const Text('HY')),
    ),
  ),
);

void main() {
  testWidgets('with no photo it shows the initials circle', (tester) async {
    await tester.pumpWidget(_host(null));
    expect(find.text('HY'), findsOneWidget);
    expect(find.byType(CachedNetworkImageWidget), findsNothing);

    await tester.pumpWidget(_host('  '));
    expect(find.text('HY'), findsOneWidget);
    expect(find.byType(CachedNetworkImageWidget), findsNothing);
  });

  testWidgets('with a photo it is a round picture, initials while it loads', (
    tester,
  ) async {
    await tester.pumpWidget(_host('https://example.com/halima.jpg'));
    expect(find.byType(ClipOval), findsOneWidget);
    expect(find.byType(CachedNetworkImageWidget), findsOneWidget);
    expect(tester.getSize(find.byType(ClipOval)), const Size(40, 40));
    expect(find.text('HY'), findsOneWidget);
  });
}
