import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_text.dart';

class DetailProfileHeader extends StatelessWidget {
  const DetailProfileHeader({
    super.key,
    required this.avatar,
    required this.name,
    this.subtitle,
  });

  final Widget avatar;
  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          avatar,
          const SizedBox(height: AppSpacing.md),
          AppText(
            name,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            colorType: AppTextColor.textInverted,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              subtitle!,
              colorType: AppTextColor.textMute,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ],
        ],
      ),
    );
  }
}
