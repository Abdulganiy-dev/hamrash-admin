import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// What was chosen on the photo options sheet.
enum AppPhotoChoice { retry, camera, library, remove }

/// 11.4 · Where a photo comes from: take one, choose one from the library,
/// or (once one is added) remove it. [canRetry] adds "Upload it again" for a
/// photo whose upload failed. Pops the choice, or null.
abstract final class AppPhotoOptionsSheet {
  AppPhotoOptionsSheet._();

  static Future<AppPhotoChoice?> show(
    BuildContext context, {
    required String title,
    String? subtitle = 'Used on their profile and class lists. JPG or PNG.',
    bool canRemove = false,
    bool canRetry = false,
  }) => AppSheet.show<AppPhotoChoice>(
    context: context,
    size: AppSheetSize.floating,
    title: title,
    subtitle: subtitle,
    bodyPadding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    body: Builder(
      builder: (context) {
        void pick(AppPhotoChoice choice) => Navigator.of(context).pop(choice);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canRetry) ...[
              _OptionRow(
                icon: AppIcons.refreshCw,
                tile: LightColors.primaryPrimaryMute,
                ink: LightColors.primaryPrimaryDefault,
                label: 'Upload it again',
                onTap: () => pick(AppPhotoChoice.retry),
              ),
              const AppDivider(indent: 0, endIndent: 0),
            ],
            _OptionRow(
              icon: AppIcons.camera,
              tile: LightColors.primaryPrimaryMute,
              ink: LightColors.primaryPrimaryDefault,
              label: 'Take a photo',
              onTap: () => pick(AppPhotoChoice.camera),
            ),
            const AppDivider(indent: 0, endIndent: 0),
            _OptionRow(
              icon: AppIcons.image,
              tile: LightColors.categoryTealMute,
              ink: LightColors.categoryTealText,
              label: 'Choose from library',
              onTap: () => pick(AppPhotoChoice.library),
            ),
            if (canRemove) ...[
              const AppDivider(indent: 0, endIndent: 0),
              _OptionRow(
                icon: AppIcons.trash2,
                tile: LightColors.errorErrorMute,
                ink: LightColors.errorErrorText,
                label: 'Remove photo',
                destructive: true,
                onTap: () => pick(AppPhotoChoice.remove),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.tile,
    required this.ink,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color tile;
  final Color ink;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AppIcon(icon, size: 20, color: ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppText(
                label,
                style: AppTypography.title.copyWith(
                  height: 22 / 16,
                  color: destructive
                      ? LightColors.errorErrorText
                      : LightColors.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
