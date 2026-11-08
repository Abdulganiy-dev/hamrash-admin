import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// A titled list on the page background: a header (title and one trailing
/// widget), then [StaffInfoRow]s with a hairline above each.
class StaffInfoSection extends StatelessWidget {
  const StaffInfoSection({
    super.key,
    required this.title,
    required this.rows,
    this.trailing,
    this.headerHeight = 32,
    this.headerKey,
  });

  final String title;

  /// A section action or a small caption, at the header's right edge.
  final Widget? trailing;
  final double headerHeight;
  final Key? headerKey;
  final List<Widget> rows;

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
            ?trailing,
          ],
        ),
      ),
      ...rows,
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

/// The hairline that sits above every row; faint dividers vanish on the
/// linen page, so it is stone-200.
class StaffRowDivider extends StatelessWidget {
  const StaffRowDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const AppDivider(indent: 0, endIndent: 0, onPage: true);
}

/// Icon, muted label and a right-aligned bold value. [value] null or empty
/// reads "Not added" in muted text. A [multiline] value wraps (the home
/// address); otherwise it stays on one line and ellipsises. With [onTap] the
/// row is a button with a chevron.
class StaffInfoRow extends StatelessWidget {
  const StaffInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool multiline;
  final VoidCallback? onTap;
  final String? semanticLabel;

  static const double rowHeight = 54;
  static const double valueMaxWidth = 190;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final empty = text.isEmpty;

    final valueText = AppText(
      empty ? 'Not added' : text,
      textAlign: TextAlign.right,
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
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: AppIcon(icon, size: 18, color: AppPalette.stone400),
        ),
        const SizedBox(width: 12),
        AppText(
          label,
          maxLines: 1,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 20 / 13,
            fontWeight: FontWeight.w600,
            color: LightColors.textBody,
          ),
        ),
        const SizedBox(width: 12),
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
            size: 16,
            color: AppPalette.stone400,
          ),
        ],
      ],
    );

    final body =
        multiline
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: row,
            )
            : SizedBox(height: rowHeight, child: row);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StaffRowDivider(),
        if (onTap == null)
          body
        else
          Semantics(
            button: true,
            label: semanticLabel ?? '$label, $text',
            excludeSemantics: true,
            child: BouncyButton(
              onPressed: onTap,
              pressedScale: 0.98,
              child: ColoredBox(color: Colors.transparent, child: body),
            ),
          ),
      ],
    );
  }
}
