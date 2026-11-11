import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// A titled section: a 32 header (title, an optional caption or action), then
/// a white card holding the rows with a faint hairline between each.
class StaffInfoSection extends StatelessWidget {
  const StaffInfoSection({
    super.key,
    required this.title,
    required this.rows,
    this.action,
    this.trailing,
    this.headerKey,
  }) : assert(
         trailing == null || action == null,
         'Provide either trailing or action, not both.',
       );

  final String title;

  /// Section action at the header's right edge, e.g. Change.
  final AppSectionAction? action;

  /// A small non-action widget at the header's right edge, e.g. a caption.
  final Widget? trailing;

  final Key? headerKey;
  final List<Widget> rows;

  /// The header's height, flush with the card below.
  static const double headerHeight = 32;

  /// Space between the header and the card.
  static const double headerGap = AppSpacing.sm;

  /// The card's padding: rows bring their own height and dividers.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        key: headerKey,
        height: headerHeight,
        child: Row(
          children: [
            Expanded(child: StaffSectionTitle(title)),
            ?action,
            ?trailing,
          ],
        ),
      ),
      const SizedBox(height: headerGap),
      AppCard(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const AppDivider(indent: 0, endIndent: 0),
              rows[i],
            ],
          ],
        ),
      ),
    ],
  );
}

class StaffSectionTitle extends StatelessWidget {
  const StaffSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => AppText(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTypography.title.copyWith(
      height: 20 / 16,
      fontWeight: FontWeight.w800,
      color: LightColors.textStrong,
    ),
  );
}

/// A 52 row inside a card: a 20 icon slot, a muted label and a right-aligned
/// bold value. [value] null or empty reads "Not added" in the disabled text
/// colour at weight 600. A [multiline] value wraps (the home address) and the
/// row top-aligns; otherwise it stays on one line and ellipsises. With
/// [onTap] the row is a button with a chevron.
class StaffInfoRow extends StatelessWidget {
  const StaffInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
    this.onTap,
    this.semanticLabel,
    this.iconOffsetY = 0,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool multiline;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Optical correction for a glyph whose visual mass isn't centred in its
  /// box (the cake sits low). Moves only the paint, not the slot.
  final double iconOffsetY;

  static const _evenLeading = TextHeightBehavior(
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const double rowHeight = 52;
  static const double valueMaxWidth = 180;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final empty = text.isEmpty;

    final valueText = Text(
      empty ? 'Not added' : text,
      textAlign: TextAlign.right,
      textHeightBehavior: _evenLeading,
      maxLines: multiline ? null : 1,
      overflow: multiline ? null : TextOverflow.ellipsis,
      style: AppTypography.body.copyWith(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: empty ? FontWeight.w600 : FontWeight.w700,
        color: empty ? LightColors.textDisabled : LightColors.textStrong,
      ),
    );

    final row = Row(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Transform.translate(
            offset: Offset(0, iconOffsetY),
            child: AppIcon(icon, size: 18, color: AppPalette.stone500),
          ),
        ),
        const SizedBox(width: AppSpacing.ms),
        // Even leading puts the glyphs in the middle of the 20px line, the
        // same centre line as the 20px icon slot, so the icon and label sit
        // on one horizontal axis.
        Text(
          label,
          maxLines: 1,
          textHeightBehavior: _evenLeading,
          style: AppTypography.body.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            color: LightColors.textBody,
          ),
        ),
        const SizedBox(width: AppSpacing.ms),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: valueMaxWidth),
              child: valueText,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          const AppIcon(
            AppIcons.chevronRight,
            size: 18,
            color: AppPalette.stone400,
          ),
        ],
      ],
    );

    final body = multiline
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: row,
          )
        : SizedBox(height: rowHeight, child: row);

    if (onTap == null) return body;
    return Semantics(
      button: true,
      label: semanticLabel ?? '$label, $text',
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: onTap,
        pressedScale: 0.98,
        child: ColoredBox(color: Colors.transparent, child: body),
      ),
    );
  }
}

/// A 64 row for the Teaching card: a 36 tinted rounded-square icon tile, a
/// small caption over a bold value, and a chevron. The whole row opens the
/// teaching sheet.
class StaffTeachingRow extends StatelessWidget {
  const StaffTeachingRow({
    super.key,
    required this.icon,
    required this.tileColor,
    required this.iconColor,
    required this.caption,
    required this.value,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color tileColor;
  final Color iconColor;

  /// e.g. "Homeroom · Assistant teacher".
  final String caption;

  /// e.g. "JSS 1A".
  final String value;

  final VoidCallback? onTap;

  /// The chevron that says the row opens something. A read-only page leaves
  /// it off.
  final bool showChevron;

  static const double rowHeight = 64;
  static const double tileSize = 36;

  @override
  Widget build(BuildContext context) {
    // At least 64 tall; a long list of arms or subjects wraps and grows it.
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: rowHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.ms),
        child: Row(
          children: [
            Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: AppRadius.brControl,
              ),
              child: Center(child: AppIcon(icon, size: 18, color: iconColor)),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LightColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    value,
                    style: AppTypography.body.copyWith(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w700,
                      color: LightColors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.sm),
              const AppIcon(
                AppIcons.chevronRight,
                size: 18,
                color: AppPalette.stone400,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return body;
    return Semantics(
      button: true,
      label: '$caption, $value',
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: onTap,
        pressedScale: 0.98,
        child: ColoredBox(color: Colors.transparent, child: body),
      ),
    );
  }
}
