import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.canCopyValue = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool canCopyValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canCopyValue
          ? () {
              HapticHelpers.vibrate(VibrationType.light);
              Clipboard.setData(ClipboardData(text: value));
              ViewUtil.showSuccessSnackBar('Copied to clipboard');
            }
          : null,
      child: AppElevatedCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: icon,
                  size: 20,
                  strokeWidth: 2,
                  color: LightColors.textTextMute,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppText(label, colorType: AppTextColor.textMute, fontSize: 13),
              ],
            ),
            Flexible(
              child: valueColor != null
                  ? AppText(
                      value,
                      color: valueColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : AppText(
                      value,
                      colorType: AppTextColor.textInverted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
