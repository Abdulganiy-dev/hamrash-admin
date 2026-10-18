import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/assets_util.dart';

void main() {
  testWidgets('svg with height only keeps its aspect ratio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(AssetsUtil.appleLogoSvg, height: 20),
                const SizedBox(width: 10),
                SvgPicture.asset(AssetsUtil.googleGSvg, height: 20),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pictures = find.byType(SvgPicture);
    // ignore: avoid_print
    print('APPLE  ${tester.getRect(pictures.at(0))}');
    // ignore: avoid_print
    print('GOOGLE ${tester.getRect(pictures.at(1))}');
  });
}
