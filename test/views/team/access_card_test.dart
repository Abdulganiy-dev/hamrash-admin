import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_access_section.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  ),
);

StaffAccessSection _section({
  required List<AccessApp> apps,
  bool isOnApp = false,
  bool isPending = false,
  bool isSuspended = false,
  VoidCallback? onAddRole,
  String? joined,
  String? invited,
}) => StaffAccessSection(
  apps: apps,
  isOnApp: isOnApp,
  isPending: isPending,
  isSuspended: isSuspended,
  joinedCaption: joined,
  invitedCaption: invited,
  onAddRole: onAddRole,
  onChangeStatus: () {},
  onToggleAccess: () {},
  onCancelInvite: () {},
  onRemove: () {},
);

void main() {
  group('Access card states (9b)', () {
    testWidgets(
      'not on app: the app row to invite, no role, status and remove',
      (tester) async {
        var invited = false;
        await _pump(
          tester,
          _section(
            apps: [
              AccessApp(
                appName: 'Hamrash Admin',
                state: AccessState.notOnApp,
                onTap: () => invited = true,
              ),
            ],
          ),
        );

        expect(find.text('Hamrash Admin'), findsOneWidget);
        expect(find.text('Not on app'), findsOneWidget);
        expect(find.text('Role'), findsNothing);
        expect(find.text('Roles'), findsNothing);
        expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
        expect(find.text('Add role'), findsNothing);
        expect(find.text('Change status'), findsOneWidget);
        expect(find.text('Suspend access'), findsNothing);
        expect(find.text('Remove from staff list'), findsOneWidget);
        expect(
          find.text('Their record is removed. Nothing else changes.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Not on app'));
        expect(invited, isTrue);
      },
    );

    testWidgets('code ready: app and role, then cancel invite', (tester) async {
      await _pump(
        tester,
        _section(
          isPending: true,
          invited: 'Invited 8 Nov',
          apps: const [
            AccessApp(
              appName: 'Hamrash Admin',
              state: AccessState.codeReady,
              roles: ['Admin'],
            ),
          ],
        ),
      );

      expect(find.text('Invited 8 Nov'), findsOneWidget);
      expect(find.text('Code ready'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Cancel invite'), findsOneWidget);
      expect(find.text('Add role'), findsNothing);
      expect(find.text('Suspend access'), findsNothing);
    });

    testWidgets('on app: Add role leads the actions', (tester) async {
      await _pump(
        tester,
        _section(
          isOnApp: true,
          joined: 'Joined 3 Sep 2026',
          onAddRole: () {},
          apps: const [
            AccessApp(
              appName: 'Hamrash Admin',
              state: AccessState.onApp,
              roles: ['Admin'],
            ),
          ],
        ),
      );

      expect(find.text('Joined 3 Sep 2026'), findsOneWidget);
      expect(find.text('On app'), findsOneWidget);
      expect(find.text('They keep the roles they have.'), findsOneWidget);
      final add = tester.getTopLeft(find.text('Add role')).dy;
      final status = tester.getTopLeft(find.text('Change status')).dy;
      final suspend = tester.getTopLeft(find.text('Suspend access')).dy;
      final remove = tester.getTopLeft(find.text('Remove from staff list')).dy;
      expect(add, lessThan(status));
      expect(status, lessThan(suspend));
      expect(suspend, lessThan(remove));
    });

    testWidgets('Add role is left out when the viewer can not add', (
      tester,
    ) async {
      await _pump(
        tester,
        _section(
          isOnApp: true,
          apps: const [
            AccessApp(
              appName: 'Hamrash Admin',
              state: AccessState.onApp,
              roles: ['Admin'],
            ),
          ],
        ),
      );

      expect(find.text('Add role'), findsNothing);
    });

    testWidgets('suspended: restore replaces suspend, no Add role', (
      tester,
    ) async {
      await _pump(
        tester,
        _section(
          isSuspended: true,
          onAddRole: () {},
          apps: const [
            AccessApp(
              appName: 'Hamrash Admin',
              state: AccessState.suspended,
              roles: ['Admin'],
            ),
          ],
        ),
      );

      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Restore access'), findsOneWidget);
      expect(find.text('Suspend access'), findsNothing);
      expect(find.text('Add role'), findsNothing);
    });

    testWidgets('both apps: one card each, each with its own Role row', (
      tester,
    ) async {
      await _pump(
        tester,
        _section(
          isOnApp: true,
          onAddRole: () {},
          apps: const [
            AccessApp(
              appName: 'Hamrash Admin',
              state: AccessState.onApp,
              roles: ['Admin'],
            ),
            AccessApp(
              appName: 'Hamrash Staff',
              state: AccessState.onApp,
              roles: ['Teacher'],
            ),
          ],
        ),
      );

      expect(find.byType(AccessAppCard), findsNWidgets(2));
      expect(find.byType(AccessActionsCard), findsOneWidget);
      expect(find.text('Hamrash Admin'), findsOneWidget);
      expect(find.text('Hamrash Staff'), findsOneWidget);
      expect(find.text('Role'), findsNWidgets(2));
      expect(find.text('Roles'), findsNothing);
      // The role rows are display only: no chevron anywhere.
      expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    });

    testWidgets('two roles on one app: one card, "Roles" joined with a dot', (
      tester,
    ) async {
      await _pump(
        tester,
        _section(
          isOnApp: true,
          apps: const [
            AccessApp(
              appName: 'Hamrash Admin',
              state: AccessState.onApp,
              roles: ['Principal', 'Bursar'],
            ),
          ],
        ),
      );

      expect(find.byType(AccessAppCard), findsOneWidget);
      expect(find.text('Roles'), findsOneWidget);
      expect(find.text('Role'), findsNothing);
      expect(find.text('Principal · Bursar'), findsOneWidget);
    });

    testWidgets('suspended on both apps: both cards read Suspended', (
      tester,
    ) async {
      await _pump(
        tester,
        _section(
          isSuspended: true,
          apps: const [
            AccessApp(
              appName: 'Hamrash Admin',
              state: AccessState.suspended,
              roles: ['Admin'],
            ),
            AccessApp(
              appName: 'Hamrash Staff',
              state: AccessState.suspended,
              roles: ['Teacher'],
            ),
          ],
        ),
      );

      expect(find.text('Suspended'), findsNWidgets(2));
      expect(find.text('Restore access'), findsOneWidget);
    });
  });
}
