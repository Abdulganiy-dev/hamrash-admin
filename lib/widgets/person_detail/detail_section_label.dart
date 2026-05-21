import 'package:flutter/material.dart';
import 'package:hamrash_admin/widgets/app_text.dart';

class DetailSectionLabel extends StatelessWidget {
  const DetailSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppText(
      label,
      colorType: AppTextColor.textInverted,
      fontWeight: FontWeight.w700,
      fontSize: 17,
    );
  }
}
