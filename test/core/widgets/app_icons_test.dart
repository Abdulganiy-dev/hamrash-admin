import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test('every icon is a Lucide glyph', () {
    const icons = <IconData>[
      AppIcons.arrowLeftRight,
      AppIcons.award,
      AppIcons.bell,
      AppIcons.bookOpen,
      AppIcons.calendar,
      AppIcons.camera,
      AppIcons.check,
      AppIcons.chevronDown,
      AppIcons.chevronLeft,
      AppIcons.chevronRight,
      AppIcons.chevronUp,
      AppIcons.circleAlert,
      AppIcons.circleCheck,
      AppIcons.circleHelp,
      AppIcons.circleMinus,
      AppIcons.circlePause,
      AppIcons.circleX,
      AppIcons.clipboardPaste,
      AppIcons.clock,
      AppIcons.copy,
      AppIcons.ellipsis,
      AppIcons.eye,
      AppIcons.eyeOff,
      AppIcons.graduationCap,
      AppIcons.house,
      AppIcons.image,
      AppIcons.info,
      AppIcons.layers,
      AppIcons.layoutGrid,
      AppIcons.lock,
      AppIcons.lockOpen,
      AppIcons.logOut,
      AppIcons.mail,
      AppIcons.messageCircle,
      AppIcons.messageSquare,
      AppIcons.minus,
      AppIcons.pencil,
      AppIcons.phone,
      AppIcons.plus,
      AppIcons.refreshCw,
      AppIcons.school,
      AppIcons.search,
      AppIcons.share,
      AppIcons.timer,
      AppIcons.toggleLeft,
      AppIcons.toggleRight,
      AppIcons.trash2,
      AppIcons.triangleAlert,
      AppIcons.userPlus,
      AppIcons.users,
      AppIcons.wallet,
      AppIcons.wifiOff,
      AppIcons.x,
    ];

    for (final icon in icons) {
      expect(
        icon.fontFamily,
        'Lucide',
        reason: 'AppIcons should only re-export Lucide glyphs',
      );
    }
  });

  test('the old weight variants collapse to one glyph', () {
    expect(AppIcons.check, LucideIcons.check);
    expect(AppIcons.x, LucideIcons.x);
    expect(AppIcons.chevronRight, LucideIcons.chevronRight);
    expect(AppIcons.circleAlert, LucideIcons.circleAlert);
    expect(AppIcons.triangleAlert, LucideIcons.triangleAlert);
    expect(AppIcons.wifiOff, LucideIcons.wifiOff);
  });

  testWidgets('a fixed-size parent does not stretch the icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: AppIcon(AppIcons.check, size: 14, color: Colors.white),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Icon)), const Size(14, 14));
    expect(tester.getSize(find.byType(AppIcon)), const Size(28, 28));
  });

  testWidgets('in a row the icon takes only its own width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [AppIcon(AppIcons.bell, size: 20), Text('label')],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppIcon)), const Size(20, 20));
  });

  testWidgets('the supplied color and semantic label reach the Icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppIcon(
            AppIcons.phone,
            size: 18,
            color: Colors.red,
            semanticLabel: 'Call',
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, Colors.red);
    expect(icon.size, 18);
    expect(icon.semanticLabel, 'Call');
  });

  testWidgets('a null icon keeps its size and draws nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppIcon(null, size: 20))),
    );

    expect(find.byType(Icon), findsNothing);
    expect(tester.getSize(find.byType(AppIcon)), const Size(20, 20));
  });
}
