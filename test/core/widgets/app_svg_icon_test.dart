import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

void main() {
  test('every icon constant points at a bundled asset', () {
    final source = File(
      'lib/core/widgets/app_svg_icon.dart',
    ).readAsStringSync();
    final paths = RegExp(
      r"assets/svg/icons/([^']+\.svg)",
    ).allMatches(source).map((match) => match.group(1)!);

    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(
        File('assets/svg/icons/$path').existsSync(),
        isTrue,
        reason:
            'AppSvgIcons references assets/svg/icons/$path, which is not '
            'in the repository (check the file name).',
      );
    }
  });

  testWidgets('a fixed-size parent does not stretch the icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: AppSvgIcon(
                AppSvgIcons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(SvgPicture)), const Size(14, 14));
    expect(tester.getSize(find.byType(AppSvgIcon)), const Size(28, 28));
  });

  testWidgets('in a row the icon takes only its own width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [AppSvgIcon(AppSvgIcons.bell, size: 20), Text('label')],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppSvgIcon)), const Size(20, 20));
  });
}
