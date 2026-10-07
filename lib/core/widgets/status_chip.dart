import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/enums/status_enums.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.label,
    this.showBackground = true,
    this.showBorderRadius = true,
    this.fontSize = 12,
  });

  final Status status;

  /// Optional override when the API label differs from [Status.label].
  final String? label;
  final bool showBackground;
  final bool showBorderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color text) = status.colors;
    return Container(
      margin:
          showBackground && showBorderRadius
              ? const EdgeInsets.only(left: AppSpacing.sm)
              : EdgeInsets.zero,
      padding:
          showBackground && showBorderRadius
              ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              )
              : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: showBackground ? bg : Colors.transparent,
        borderRadius:
            showBorderRadius
                ? BorderRadius.circular(AppRadius.pill)
                : BorderRadius.zero,
        border: showBackground ? Border.all(color: border, width: 1) : null,
      ),
      child: AppText(
        label ?? status.label,
        color: text,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({
    super.key,
    required this.priority,
    this.showBackground = true,
    this.showBorderRadius = true,
    this.fontSize = 12,
  });

  final Priority priority;
  final bool showBackground;
  final bool showBorderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color text) = priority.colors;
    return Container(
      margin:
          showBackground && showBorderRadius
              ? const EdgeInsets.only(left: AppSpacing.sm)
              : EdgeInsets.zero,
      padding:
          showBackground && showBorderRadius
              ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              )
              : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: showBackground ? bg : Colors.transparent,
        borderRadius:
            showBorderRadius
                ? BorderRadius.circular(AppRadius.pill)
                : BorderRadius.zero,
        border: showBackground ? Border.all(color: border, width: 1) : null,
      ),
      child: AppText(
        priority.label,
        color: text,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
