import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// A fixed icon slot and a label, laid out the way the sign-in buttons are:
/// the mark is centred in a square slot, an optical [markOffsetY] moves only
/// its paint, and the group is centred as one. The label is capped to the
/// room left beside the slot, so it ellipsizes instead of pushing the group
/// off centre.
class IconLabel extends StatelessWidget {
  const IconLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.style,
    required this.iconColor,
    this.iconSize = 18,
    this.gap = 6,
    this.markOffsetY = 0,
  });

  final AppSvgIconData icon;
  final String label;
  final TextStyle style;
  final Color iconColor;

  /// Size of the square slot the mark is centred in.
  final double iconSize;
  final double gap;

  /// Optical correction for a mark whose visual mass is not centred in its
  /// box. Moves only the paint, not the slot, the gap or the label.
  final double markOffsetY;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelWidth = math.max(0.0, constraints.maxWidth - iconSize - gap);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: iconSize,
            child: Transform.translate(
              offset: Offset(0, markOffsetY),
              child: AppSvgIcon(icon, size: iconSize, color: iconColor),
            ),
          ),
          SizedBox(width: gap),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: labelWidth),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      );
    },
  );
}
