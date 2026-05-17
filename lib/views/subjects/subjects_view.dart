import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/subjects_view_model.dart';
import 'package:hamrash_admin/views/subjects/create_edit_subject_view.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openCreateEdit(context, model),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedAdd01,
            strokeWidth: 2,
            size: 24,
          ),
        ),
        body: Builder(
          builder: (context) {
            if (model.subjects.isEmpty && !model.busy) {
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
                      children: List.generate(model.subjects.length, (i) {
                        final subject = model.subjects[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == model.subjects.length - 1
                                ? 0
                                : AppSpacing.xs,
                          ),
                          child: _subjectItem(context, model, subject),
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

  Widget _subjectItem(
    BuildContext context,
    SubjectsViewModel model,
    SubjectModel subject,
  ) {
    return GestureDetector(
      onTap: () => _openCreateEdit(context, model, existing: subject),
      child: AppElevatedCard(
        child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  Colors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedBook02,
                size: 22,
                strokeWidth: 2,
                color: Colors.teal,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  subject.name,
                  colorType: AppTextColor.textInverted,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subject.description != null &&
                    subject.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AppText(
                    subject.description!,
                    colorType: AppTextColor.textMute,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, model, subject),
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
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEditSubjectView(
          existing: existing,
          viewModel: model,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SubjectsViewModel model,
    SubjectModel subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Delete "${subject.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await model.deleteSubject(subject);
    }
  }
}
