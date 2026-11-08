import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// One row in a [StaffRowsCard]: a label and, on the right, a value, anything
/// custom, or a chevron when the row opens something.
class StaffRow extends StatelessWidget {
  const StaffRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.isWarning = false,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;

  /// A read-only value on the right. Empty renders a muted "Not added".
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// The suspend/restore row reads in the warning colour.
  final bool isWarning;

  /// Set false when a trailing word already says the row opens something.
  final bool showChevron;

  String get _valueText {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not added' : text;
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = isWarning
        ? LightColors.warningWarningText
        : LightColors.textStrong;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  title,
                  style: AppTypography.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                if (subtitle case final line?) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    line,
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.stone500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: AppSpacing.ms),
            Flexible(
              child: AppText(
                _valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: value!.trim().isEmpty
                      ? LightColors.textMuted
                      : LightColors.textBody,
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
          if (onTap != null && showChevron) ...[
            const SizedBox(width: AppSpacing.xs),
            const AppSvgIcon(
              AppSvgIcons.chevronRight500,
              size: 18,
              color: AppPalette.stone400,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return BouncyButton(onPressed: onTap, pressedScale: 0.98, child: row);
  }
}

/// A white card of [StaffRow]s with hairlines between them.
class StaffRowsCard extends StatelessWidget {
  const StaffRowsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppPalette.stone100,
            ),
          children[i],
        ],
      ],
    ),
  );
}
