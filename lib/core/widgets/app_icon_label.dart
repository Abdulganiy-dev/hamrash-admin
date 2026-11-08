import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// A fixed icon slot and a label, laid out the way the sign-in buttons are:
/// the mark is centred in a square slot, an optional optical [markOffsetY]
/// moves only its paint, and the group is centred as one.
///
/// Leave [hugContent] false in a full-width button: the label is capped to
/// the room left beside the slot. Set it true inside a pill that should size
/// itself to the icon and label.
class AppIconLabel extends StatelessWidget {
  const AppIconLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.style,
    required this.iconColor,
    this.iconSize = 18,
    this.gap = 6,
    this.markOffsetY = 0,
    this.hugContent = false,
  });

  final IconData icon;
  final String label;
  final TextStyle style;
  final Color iconColor;

  /// Size of the square slot the mark is centred in.
  final double iconSize;
  final double gap;

  /// Optical correction for a mark whose visual mass is not centred in its
  /// box. Moves only the paint, not the slot, the gap or the label.
  final double markOffsetY;

  /// Sizes the row to its content instead of the available width.
  final bool hugContent;

  Widget _slot() => SizedBox.square(
    dimension: iconSize,
    child: Transform.translate(
      offset: Offset(0, markOffsetY),
      child: AppIcon(icon, size: iconSize, color: iconColor),
    ),
  );

  Widget _text([double? maxWidth]) {
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    if (maxWidth == null) return text;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hugContent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _slot(),
          SizedBox(width: gap),
          _text(),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = math.max(0.0, constraints.maxWidth - iconSize - gap);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _slot(),
            SizedBox(width: gap),
            _text(labelWidth),
          ],
        );
      },
    );
  }
}
