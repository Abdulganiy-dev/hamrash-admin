import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';

/// One scrolling row of [AppFilterChip]s — the filter row at the top of a
/// list. It never wraps: the chips run off the right edge and the next one
/// scrolls in.
///
/// [inset] is the breathing room at both ends. Leave it at the default when
/// the row sits straight on the page (the chips then start on the screen
/// margin and bleed off the right edge). Set it to [AppSpacing.none] when the
/// page already pads the content, as inside an [AppRefreshScrollView] with
/// its default screen padding.
///
/// For chips inside a sheet or a form, keep a [Wrap] with 8px
/// `spacing`/`runSpacing` instead of this widget.
class AppChipRow extends StatelessWidget {
  const AppChipRow({
    super.key,
    required this.children,
    this.inset = AppSpacing.md,
    this.spacing = AppSpacing.sm,
  });

  final List<Widget> children;

  /// Space before the first chip and after the last. Not a left/right page
  /// margin when the page already supplies one.
  final double inset;

  /// Space between chips.
  final double spacing;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    padding: EdgeInsets.symmetric(horizontal: inset, vertical: AppSpacing.xs),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) SizedBox(width: spacing),
          child,
        ],
      ],
    ),
  );
}
