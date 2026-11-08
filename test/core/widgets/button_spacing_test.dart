import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_result_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/app_sheet_link_action.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// Visible space between the bottom of [top] and the top of [bottom].
double _visibleGap(WidgetTester tester, Finder top, Finder bottom) =>
    tester.getRect(bottom).top - tester.getRect(top).bottom;

void main() {
  group('stacked buttons sit 16 apart', () {
    testWidgets('AppConfirmSheet confirm over cancel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppConfirmSheet(
              title: 'Close 2025/26?',
              message: 'It becomes history and cannot be edited.',
              confirmLabel: 'Close 2025/26',
              cancelLabel: 'Not now',
            ),
          ),
        ),
      );

      expect(
        _visibleGap(
          tester,
          find.byType(AppPrimaryButton),
          find.byType(AppSecondaryButton),
        ),
        AppSpacing.md,
      );
    });

    testWidgets('AppResultSheet button over its text action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppResultSheet(
              type: AppResultType.success,
              message: 'Payment recorded.',
              secondaryLabel: 'Record another',
            ),
          ),
        ),
      );

      // The text button's 48px tap area carries 12 above its label, so the
      // visible gap runs from the primary button's edge to the label.
      expect(
        _visibleGap(
          tester,
          find.byType(AppPrimaryButton),
          find.text('Record another'),
        ),
        AppSpacing.md,
      );
    });

    testWidgets('AppEmptyState button over its text link', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: AppIcons.users,
              title: 'No students yet',
              subtitle: 'Add them one by one.',
              actionLabel: 'Add student',
              onAction: () {},
              secondaryLabel: 'Import class list',
              onSecondary: () {},
            ),
          ),
        ),
      );

      expect(
        _visibleGap(
          tester,
          find.byType(AppPrimaryButton),
          find.text('Import class list'),
        ),
        AppSpacing.md,
      );
    });

    testWidgets('AppSheetLinkAction from a button and from each other', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPrimaryButton(
                      onPressed: () {},
                      child: const AppText('Save class'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSheetLinkAction(
                      icon: AppIcons.eyeOff,
                      label: 'Switch off this class',
                      onPressed: () {},
                    ),
                    // Two link actions are 12 apart: the first carries 4
                    // under its label, which reads as 16.
                    const SizedBox(height: AppSpacing.ms),
                    AppSheetLinkAction(
                      icon: AppIcons.trash2,
                      label: 'Remove class',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        _visibleGap(
          tester,
          find.byType(AppPrimaryButton),
          find.text('Switch off this class'),
        ),
        AppSpacing.md,
      );
      expect(
        _visibleGap(
          tester,
          find.text('Switch off this class'),
          find.text('Remove class'),
        ),
        AppSpacing.md,
      );
    });
  });

  testWidgets('a text link keeps a 44px tap area', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: AppIcons.users,
            title: 'No students yet',
            subtitle: 'Add them one by one.',
            actionLabel: 'Add student',
            onAction: () {},
            secondaryLabel: 'Import class list',
            onSecondary: () {},
          ),
        ),
      ),
    );

    final tapTarget = find.ancestor(
      of: find.text('Import class list'),
      matching: find.byType(BouncyButton),
    );
    expect(tester.getSize(tapTarget).height, greaterThanOrEqualTo(44));
  });
}
