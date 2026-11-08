import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/views/team/widgets/staff_invite_card.dart';

void main() {
  testWidgets('both bands start at the same left edge and span the card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StaffInviteCard(code: 'K7M2-QX9P', onTap: () {}),
          ),
        ),
      ),
    );

    final cardLeft = tester.getTopLeft(find.byType(StaffInviteCard)).dx;
    final codeLeft = tester.getTopLeft(find.text('INVITE CODE')).dx;
    final expiresLeft = tester.getTopLeft(find.text('EXPIRES')).dx;
    final neverLeft = tester.getTopLeft(find.text('Never')).dx;

    expect(codeLeft, cardLeft + 16 + 1); // padding + border
    expect(expiresLeft, codeLeft);
    expect(neverLeft, codeLeft);
  });
}
