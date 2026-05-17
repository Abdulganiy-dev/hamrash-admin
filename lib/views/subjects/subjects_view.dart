import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/subjects_view_model.dart';
import 'package:hamrash_admin/views/subjects/create_edit_subject_view.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/warning_modal.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

class SubjectsView extends StatefulWidget {
  const SubjectsView({super.key});
  static const String routeName = '/subjects';

  @override
  State<SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<SubjectsView> {
  late SubjectsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SubjectsViewModel>.reactive(
      viewModelBuilder: () => SubjectsViewModel(),
      onViewModelReady: (model) {
        viewModel = model;
        model.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
        title: 'Subjects',
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
            if (model.subjects.isEmpty && !model.busy) {
              return _emptyState(context);
            }
            return SingleChildScrollView(
              child: ScaffoldColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: ScaffoldInsets.of(context).bodyTopInset + 15,
                  ),
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: model.subjects.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final subject = model.subjects[index];
                      return _subjectItem(context, model, subject);
                    },
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

  Widget _subjectItem(
    BuildContext context,
    SubjectsViewModel model,
    SubjectModel subject,
  ) {
    return Dismissible(
      key: Key(subject.id!),
      direction: DismissDirection.endToStart,
      background: _deleteSwipeBackground(),
      confirmDismiss: (_) => _confirmDelete(context, model, subject),
      child: GestureDetector(
        onTap: () => _openCreateEdit(context, model, existing: subject),
        child: SizedBox(
          height: 50,
          child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBook02,
              size: 22,
              strokeWidth: 2,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  subject.name,
                  colorType: AppTextColor.textInverted,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
              ],
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
      ),
    );
  }

  Widget _deleteSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: LightColors.errorErrorDefault,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const HugeIcon(
        icon: HugeIcons.strokeRoundedDelete02,
        size: 22,
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedBook02,
            size: 64,
            strokeWidth: 1.5,
            color: Colors.grey,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            'No subjects yet',
            colorType: AppTextColor.textInverted,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Tap the + button to add your first subject',
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
    SubjectsViewModel model, {
    SubjectModel? existing,
  }) {
    return CreateEditSubjectView.openSheet(
      context,
      existing: existing,
      viewModel: model,
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    SubjectsViewModel model,
    SubjectModel subject,
  ) async {
    final classCount = await model.subjectClassCount(subject.id!);
    if (!context.mounted) return false;

    if (classCount > 0) {
      final noun = classCount == 1 ? 'class' : 'classes';
      await WarningModal.show(
        context,
        title: 'Cannot Delete Subject',
        message:
            '"${subject.name}" is assigned to $classCount $noun. Remove it from all classes before deleting.',
      );
      return false;
    }

    final confirmed = await WarningModal.show<bool>(
      context,
      message: 'Delete "${subject.name}"? This cannot be undone.',
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
    if (confirmed != true) return false;
    return model.deleteSubject(subject);
  }
   
  
}
