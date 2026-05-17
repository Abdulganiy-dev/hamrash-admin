import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/section_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/classes_view_model.dart';
import 'package:hamrash_admin/views/classes/add_arm_sheet.dart';
import 'package:hamrash_admin/views/classes/add_class_sheet.dart';
import 'package:hamrash_admin/views/classes/create_edit_class_view.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/warning_modal.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

class ClassesView extends StatefulWidget {
  const ClassesView({super.key});
  static const String routeName = '/classes';

  @override
  State<ClassesView> createState() => _ClassesViewState();
}

class _ClassesViewState extends State<ClassesView> {
  late ClassesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ClassesViewModel>.reactive(
      viewModelBuilder: () => ClassesViewModel(),
      onViewModelReady: (model) {
        viewModel = model;
        model.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
        title: 'Classes',
        showBackButton: true,
        busy: model.busy,
        appBarType: DefaultScaffoldAppBarType.standard,
        body: Builder(
          builder: (context) {
            return SingleChildScrollView(
              child: ScaffoldColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ScaffoldInsets.of(context).bodyTopInset + 15),
                  _SectionHeader(
                    title: 'Arms',
                    onAdd: () => AddArmSheet.openSheet(context, viewModel: model),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _armsRow(context, model),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(
                    title: 'Classrooms',
                    onAdd: () => AddClassSheet.openSheet(context, viewModel: model),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _classroomsSection(context, model),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _armsRow(BuildContext context, ClassesViewModel model) {
    if (model.arms.isEmpty && !model.busy) {
      return AppText(
        'No arms yet. Tap + to add one.',
        colorType: AppTextColor.textMute,
        fontSize: 13,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: model.arms.map((arm) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _ArmChip(
              arm: arm,
              onDelete: () => _confirmDeleteArm(context, model, arm),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _classroomsSection(BuildContext context, ClassesViewModel model) {
    final grouped = model.groupedClasses;
    if (grouped.isEmpty && !model.busy) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSchool,
                size: 48,
                strokeWidth: 1.5,
                color: LightColors.textTextMute,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'No classrooms yet',
                colorType: AppTextColor.textInverted,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                'Tap + to add your first classroom',
                colorType: AppTextColor.textMute,
                fontSize: 13,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _classGroup(context, model, entry.key, entry.value),
        );
      }).toList(),
    );
  }

  Widget _classGroup(
    BuildContext context,
    ClassesViewModel model,
    String groupName,
    List<ClassModel> classes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        AppText(
          groupName,
          colorType: AppTextColor.textMute,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ).padding(bottom: AppSpacing.xs),
        AppSurfaceCard(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: List.generate(classes.length, (i) {
              final cls = classes[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == classes.length - 1 ? 0 : AppSpacing.xs,
                ),
                child: _classroomItem(context, model, cls),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _classroomItem(
    BuildContext context,
    ClassesViewModel model,
    ClassModel cls,
  ) {
    return GestureDetector(
      onTap: () => CreateEditClassView.openSheet(
        context,
        existing: cls,
        availableSubjects: model.subjects,
        availableArms: model.arms,
        viewModel: model,
      ),
      child: AppElevatedCard(
        child: Row(
          children: [
            Expanded(
              child: AppText(
                cls.displayName,
                colorType: AppTextColor.textInverted,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => _confirmDeleteClass(context, model, cls),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 18,
                  strokeWidth: 2,
                  color: LightColors.textTextMute,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              strokeWidth: 2,
              color: LightColors.textTextMute,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteArm(
    BuildContext context,
    ClassesViewModel model,
    SectionModel arm,
  ) async {
    if (model.armIsUsed(arm.name)) {
      await WarningModal.show(
        context,
        title: 'Cannot Delete Arm',
        message:
            'Remove all classrooms using arm "${arm.name}" before deleting it.',
      );
      return;
    }
    final confirmed = await WarningModal.show<bool>(
      context,
      message: 'Delete arm "${arm.name}"?',
      subtitle: 'This cannot be undone.',
      bottomBody: Row(
        children: [
          Expanded(
            child: AppTertiaryButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppPrimaryButton(
              backgroundColorType: AppButtonBackgroundColor.error,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await model.deleteArm(arm);
    }
  }

  Future<void> _confirmDeleteClass(
    BuildContext context,
    ClassesViewModel model,
    ClassModel cls,
  ) async {
    final hasSubjects = await model.classHasSubjects(cls.id!);
    if (!context.mounted) return;

    if (hasSubjects) {
      await WarningModal.show(
        context,
        title: 'Cannot Delete Classroom',
        message:
            'Remove all subject assignments from "${cls.displayName}" before deleting it.',
      );
      return;
    }

    final confirmed = await WarningModal.show<bool>(
      context,
      message: 'Delete "${cls.displayName}"?',
      subtitle: 'This cannot be undone.',
      bottomBody: Row(
        children: [
          Expanded(
            child: AppTertiaryButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppPrimaryButton(
              backgroundColorType: AppButtonBackgroundColor.error,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await model.deleteClass(cls);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          title,
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        const Spacer(),
        AppHugeIconButton(
            hugeIcon: HugeIcons.strokeRoundedAdd01,
            hugeIconStrokeWidth: 2,
            hugeIconRasterSize: 25,
            foregroundColorType: AppButtonForegroundColor.textInverted,
            onPressed: onAdd,
          ),
      ],
    );
  }
}

class _ArmChip extends StatelessWidget {
  const _ArmChip({required this.arm, required this.onDelete});

  final SectionModel arm;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = LightColors.strokeColourStrokeMild;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd2,
        vertical: AppSpacing.xsSm,
      ),
      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            arm.name,
            colorType: AppTextColor.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: LightColors.textTextMute,
            ),
          ),
        ],
      ),
    );
  }
}
