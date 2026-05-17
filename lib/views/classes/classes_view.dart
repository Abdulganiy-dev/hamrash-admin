import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/classes_view_model.dart';
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
        actions: [
          AppHugeIconButton(
            hugeIcon: HugeIcons.strokeRoundedAdd01,
            hugeIconStrokeWidth: 2,
            hugeIconRasterSize: 30,
            foregroundColorType: AppButtonForegroundColor.textInverted,
            onPressed: () => _openCreateEdit(context, model),
          ),
        ],
        appBarType: DefaultScaffoldAppBarType.standard,

        body: Builder(
          builder: (context) {
            if (model.classes.isEmpty && !model.busy) {
              return _emptyState(context);
            }
            return SingleChildScrollView(
              child: ScaffoldColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: ScaffoldInsets.of(context).bodyTopInset + 15,
                  ),
                  AppSurfaceCard(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: List.generate(model.classes.length, (i) {
                        final cls = model.classes[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == model.classes.length - 1
                                ? 0
                                : AppSpacing.xs,
                          ),
                          child: _classItem(context, model, cls),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _classItem(
    BuildContext context,
    ClassesViewModel model,
    ClassModel cls,
  ) {
    return GestureDetector(
      onTap: () => _openCreateEdit(context, model, existing: cls),
      child: AppElevatedCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSchool,
                  size: 22,
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    cls.displayName,
                    colorType: AppTextColor.textInverted,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    cls.isActive ? 'Active' : 'Inactive',
                    colorType: cls.isActive
                        ? AppTextColor.textPrimary
                        : AppTextColor.textMute,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _confirmDelete(context, model, cls),
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

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSchool,
            size: 64,
            strokeWidth: 1.5,
            color: LightColors.textTextMute,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            'No classes yet',
            colorType: AppTextColor.textInverted,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Tap the + button to add your first class',
            colorType: AppTextColor.textMute,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            textAlign: TextAlign.center,
          ).padding(left: AppSpacing.xl, right: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _openCreateEdit(
    BuildContext context,
    ClassesViewModel model, {
    ClassModel? existing,
  }) {
    return CreateEditClassView.openSheet(
      context,
      existing: existing,
      availableSubjects: model.subjects,
      viewModel: model,
    );
  }


  Future<void> _confirmDelete(
    BuildContext context,
    ClassesViewModel model,
    ClassModel cls,
  ) async {
    final hasSubjects = await model.classHasSubjects(cls.id!);
    if (!context.mounted) return;

    if (hasSubjects) {
      await WarningModal.show(
        context,
        title: 'Cannot Delete Class',
        message:
            'Remove all subject assignments from "${cls.displayName}" before deleting it.',
      );
      return;
    }

    final confirmed = await WarningModal.show<bool>(
      context,
      message: 'Delete "${cls.displayName}"? This cannot be undone.',
      subtitle: 'This cannot be undone.',
      bottomBody: Row(
        children: [
          Expanded(child: AppTertiaryButton(backgroundColorType: AppButtonBackgroundColor.error,foregroundColor:Colors.white,onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel'))),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: AppPrimaryButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete'))),
        ],
      ),
    );
    if (confirmed == true) {
      await model.deleteClass(cls);
    }
  }
}
