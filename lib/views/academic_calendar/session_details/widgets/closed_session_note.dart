import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// 4.8 · Under a closed session: it's kept as history. The owner can reopen
/// it ([onReopen]); everyone else just sees the note.
class ClosedSessionNote extends StatelessWidget {
  const ClosedSessionNote({
    super.key,
    required this.sessionName,
    this.onReopen,
  });

  final String sessionName;
  final VoidCallback? onReopen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppPalette.stone100,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSvgIcon(AppSvgIcons.info, size: 18, color: AppPalette.stone600),
            SizedBox(width: 10),
            Expanded(
              child: AppText(
                'This year is kept as history. Its classes, subjects and '
                'results can be viewed but not changed.',
                variant: AppTextVariant.body,
                colorType: AppTextColor.textBody,
              ),
            ),
          ],
        ),
        if (onReopen != null) ...[
          const SizedBox(height: 12),
          AppSecondaryButton(
            height: 44,
            onPressed: onReopen,
            child: Text('Reopen $sessionName'),
          ),
          const SizedBox(height: 8),
          AppText(
            'Only you, as the owner, can do this',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppPalette.stone500),
          ),
        ],
      ],
    ),
  );
}
