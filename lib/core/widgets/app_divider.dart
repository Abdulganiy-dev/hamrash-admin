import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';

/// The one divider between rows inside a card, list or sheet: 1px, faint.
///
/// [faint] is stone-50 on white cards and white sheets. On the linen page
/// stone-50 vanishes, so pass [onPage] for stone-100. Never use it for a
/// card's outer edge, a field, chip or button border; those keep their own
/// strokes.
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

  /// The faint divider colour, stone-50; [onPage] lifts it to stone-100.
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
