import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/person_detail/info_row.dart';
import 'package:hugeicons/hugeicons.dart';

class DetailInfoEntry {
  const DetailInfoEntry({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.canCopyValue = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool canCopyValue;
}

class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({super.key, required this.entries});

  final List<DetailInfoEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return AppSurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            InfoRow(
              icon: entries[i].icon,
              label: entries[i].label,
              value: entries[i].value,
              valueColor: entries[i].valueColor,
              canCopyValue: entries[i].canCopyValue,
            ),
          ],
        ],
      ),
    );
  }
}

bool hasContactInfo({String? email, String? phone}) =>
    email != null || phone != null;

DetailInfoCard contactInfoCard({String? email, String? phone}) {
  return DetailInfoCard(
    entries: [
      if (email != null)
        DetailInfoEntry(
          icon: HugeIcons.strokeRoundedMail01,
          label: 'Email',
          value: email,
        ),
      if (phone != null)
        DetailInfoEntry(
          icon: HugeIcons.strokeRoundedSmartPhone01,
          label: 'Phone',
          value: phone,
        ),
    ],
  );
}

DetailInfoCard accountStatusCard({required bool isActive}) {
  return DetailInfoCard(
    entries: [
      DetailInfoEntry(
        icon: isActive
            ? HugeIcons.strokeRoundedCheckmarkCircle01
            : HugeIcons.strokeRoundedCancelCircle,
        label: 'Account',
        value: isActive ? 'Active' : 'Inactive',
        valueColor:
            isActive ? Colors.green : LightColors.errorErrorDefault,
      ),
    ],
  );
}
