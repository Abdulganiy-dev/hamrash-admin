import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';

/// Change how a parent is related to the student. Pops the new relationship,
/// or null when closed.
class ParentRelationshipSheet extends StatefulWidget {
  const ParentRelationshipSheet({
    super.key,
    required this.parentName,
    required this.current,
  });

  final String parentName;
  final ParentRelationship current;

  static Future<ParentRelationship?> show(
    BuildContext context, {
    required String parentName,
    required ParentRelationship current,
  }) => Navigator.of(context).push<ParentRelationship>(
    AppSheetRoute<ParentRelationship>(
      size: AppSheetSize.floating,
      child: ParentRelationshipSheet(parentName: parentName, current: current),
    ),
  );

  @override
  State<ParentRelationshipSheet> createState() =>
      _ParentRelationshipSheetState();
}

class _ParentRelationshipSheetState extends State<ParentRelationshipSheet> {
  late ParentRelationship _selected = widget.current;

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Change relationship',
    subtitle: 'For ${widget.parentName}',
    bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final relationship in ParentRelationship.values)
          Semantics(
            button: true,
            selected: _selected == relationship,
            child: BouncyButton(
              key: ValueKey('relationship-${relationship.value}'),
              onPressed: () => setState(() => _selected = relationship),
              pressedScale: 0.98,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        relationship.label,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: _selected == relationship
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: LightColors.textStrong,
                        ),
                      ),
                    ),
                    AppRadio<ParentRelationship>(
                      value: relationship,
                      groupValue: _selected,
                      onChanged: (_) =>
                          setState(() => _selected = relationship),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
    footer: AppPrimaryButton(
      useGradient: true,
      height: 52,
      isDisabled: _selected == widget.current,
      onPressed: _selected == widget.current
          ? null
          : () => Navigator.of(context).pop(_selected),
      child: const Text('Save relationship'),
    ),
  );
}
