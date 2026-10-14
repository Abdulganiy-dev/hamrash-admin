import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// "MTH" on a stone chip, the same width in every row so names line up.
class SubjectCodeChip extends StatelessWidget {
  const SubjectCodeChip({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 26,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppPalette.stone100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: AppText(
      subject.shortLabel,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: AppTypography.label.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: subject.isActive
            ? LightColors.textBody
            : LightColors.textDisabled,
      ),
    ),
  );
}
