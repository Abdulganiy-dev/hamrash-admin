import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/selection/app_option_card.dart';
import 'package:hamrash_admin/views/classes/classes_view_model.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// 6.1 · A school with no classes picks how to start: the usual Nigerian
/// structure, or its own sections from scratch.
class StructureStartPicker extends StatelessWidget {
  const StructureStartPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StructureStart value;
  final ValueChanged<StructureStart> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const AppOptionsIntro(
        title: 'How do you want to start?',
        body: 'You can rename, reorder or switch off anything later.',
      ),
      const SizedBox(height: 20),
      AppOptionCard(
        title: 'Standard structure',
        badge: 'Recommended',
        subtitle: '15 classes in 3 sections. You add the arms next.',
        value: StructureStart.standard,
        groupValue: value,
        onChanged: onChanged,
        details: const AppOptionSummary(
          rows: [
            ('Nursery', 'Nursery 1 – 3'),
            ('Primary', 'Primary 1 – 6'),
            ('Secondary', 'JSS 1 – SS 3'),
          ],
          note: 'Students graduate after SS 3',
          noteIcon: AppSvgIcons.graduationCap,
        ),
      ),
      const SizedBox(height: 12),
      AppOptionCard(
        title: 'Start from scratch',
        subtitle:
            'Add your own sections and classes, e.g. a primary-only school.',
        value: StructureStart.scratch,
        groupValue: value,
        onChanged: onChanged,
      ),
    ],
  );
}
