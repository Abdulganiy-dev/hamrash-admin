import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';

/// The one divider between rows inside a card, list or sheet: 1px, faint.
///
/// Faint ([faint], stone-100) on white cards, white sheets and stone-50
/// groups. On the linen page stone-100 disappears, so pass [onPage] to keep
/// stone-200. Never use it for a card's outer edge, a field, chip or button
/// border; those keep their own strokes.
class AppDivider extends StatelessWidget {
  /// A horizontal 1px rule inset by [indent] and [endIndent].
  const AppDivider({
    super.key,
    this.indent = 16,
    this.endIndent = 16,
    this.onPage = false,
  }) : vertical = false;

  /// A full-height vertical 1px rule, for key/value grids. Fills the height
  /// its parent gives it.
  const AppDivider.vertical({super.key, this.onPage = false})
    : vertical = true,
      indent = 0,
      endIndent = 0;

  /// The faint divider colour, defined once (`--color-stone-100`).
  static const faint = AppPalette.stone50;

  /// Left inset, from the card edge.
  final double indent;

  /// Right inset, from the card edge.
  final double endIndent;

  /// True on the linen page background, where [faint] would vanish.
  final bool onPage;

  final bool vertical;

  Color get color => onPage ? AppPalette.stone100 : faint;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return SizedBox(width: 1, child: ColoredBox(color: color));
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: color),
      ),
    );
  }
}
