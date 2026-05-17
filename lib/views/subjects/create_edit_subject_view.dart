import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/subjects_view_model.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';
import 'package:hamrash_admin/widgets/button/app_button.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/glass_sheet.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

class CreateEditSubjectView extends StatefulWidget {
  const CreateEditSubjectView({
    super.key,
    this.existing,
    required this.viewModel,
  });

  final SubjectModel? existing;
  final SubjectsViewModel viewModel;

  static Future<bool?> openSheet(
    BuildContext context, {
    SubjectModel? existing,
    required SubjectsViewModel viewModel,
  }) {
    final isEdit = existing != null;
    return GlassSheet.show<bool>(
      context: context,
      title: isEdit ? 'Edit Subject' : 'New Subject',
      snappingConfig: const SheetSnappingConfig([0.45, 0.65]),
      body: CreateEditSubjectView(
        existing: existing,
        viewModel: viewModel,
      ),
    );
  }

  @override
  State<CreateEditSubjectView> createState() => _CreateEditSubjectViewState();
}

class _CreateEditSubjectViewState extends State<CreateEditSubjectView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    bool success;
    if (_isEdit) {
      success = await widget.viewModel.updateSubject(
        existing: widget.existing!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
    } else {
      success = await widget.viewModel.createSubject(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _submitting = false);
      if (success) NavigationService.popScreen(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Subject Name',
              hintText: 'e.g. Mathematics, English Language',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a subject name'
                  : null,
            ).padding(bottom: AppSpacing.md),
            AppTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              hintText: 'Brief description of the subject',
              maxLines: 3,
            ).padding(bottom: AppSpacing.lg),
            AppButton(
              type: AppButtonType.primary,
              text: _isEdit ? 'Save Changes' : 'Create Subject',
              isDisabled: _submitting,
              onPressed: _submit,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
