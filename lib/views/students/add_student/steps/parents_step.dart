import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_action_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_dashed_border.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/add_parent_sheet.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/parent_card.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/step_lead.dart';

/// 11.5 / 11.6 · Step 2: at least one parent or guardian, exactly one of
/// them the main contact (the first added, until another is made main).
class ParentsStep extends StatelessWidget {
  const ParentsStep({super.key, required this.model});

  final AddStudentViewModel model;

  Future<void> _add(BuildContext context) =>
      AddParentSheet.show(context, model: model);

  void _actions(BuildContext context, int index) {
    final parent = model.parents[index];
    final isMain = index == model.mainIndex;
    AppActionSheet.show(
      context,
      title: parent.displayName,
      subtitle: parent.caption,
      leading: AppLeadingPicture(leading: parentLeading(parent), size: 44),
      groups: [
        if (!isMain)
          [
            AppSheetAction(
              label: 'Make main contact',
              icon: AppIcons.phone,
              onTap: () => model.makeMain(index),
            ),
          ],
        [
          AppSheetAction(
            label: 'Remove from this student',
            icon: AppIcons.trash2,
            isDestructive: true,
            onTap: () => model.removeParent(index),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final parents = model.parents;
    return StepScroll(
      children: [
        StepLead(
          eyebrow: model.stepEyebrow(AddStudentStep.parents),
          title: 'Who are the parents?',
          body:
              'Add at least one parent or guardian. The main contact is who '
              'the school calls first.',
        ),
        if (parents.isEmpty)
          _NoParents(onAdd: () => _add(context))
        else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < parents.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.ms),
                ParentCard(
                  parent: parents[i],
                  isMain: i == model.mainIndex,
                  onMakeMain: () => model.makeMain(i),
                  onTap: () => _actions(context, i),
                ),
              ],
            ],
          ),
          _AddAnother(onTap: () => _add(context)),
        ],
      ],
    );
  }
}

class _NoParents extends StatelessWidget {
  const _NoParents({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => AppDashedBorder(
    radius: 20,
    fill: AppPalette.white,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ml,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LightColors.primaryPrimaryMute,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const AppIcon(
              AppIcons.userPlus,
              size: 26,
              color: LightColors.primaryPrimaryDefault,
            ),
          ),
          const SizedBox(height: 14),
          AppText(
            'No parent added yet',
            textAlign: TextAlign.center,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w800,
              height: 24 / 18,
              color: LightColors.textStrong,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Search by phone first, so a parent who already has a child here '
            'is found for you.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: LightColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.ml),
          AppPrimaryButton(
            onPressed: onAdd,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ml),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.plus, size: 16),
                SizedBox(width: AppSpacing.sm),
                Text('Add a parent'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AddAnother extends StatelessWidget {
  const _AddAnother({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add another parent',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: AppDashedBorder(
        radius: 16,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(
                AppIcons.plus,
                size: 18,
                color: LightColors.primaryPrimaryDefault,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppText(
                'Add another parent',
                style: AppTypography.button.copyWith(
                  fontSize: 15,
                  color: LightColors.primaryPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
