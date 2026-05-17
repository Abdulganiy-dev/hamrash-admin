import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/subjects_view_model.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';
import 'package:hamrash_admin/widgets/button/app_button.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';

class CreateEditSubjectView extends StatefulWidget {
  const CreateEditSubjectView({
    super.key,
    this.existing,
    required this.viewModel,
  });

  final SubjectModel? existing;
  final SubjectsViewModel viewModel;

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
    return DefaultScaffold(
      title: _isEdit ? 'Edit Subject' : 'New Subject',
      showBackButton: true,
      busy: _submitting,
      body: Builder(
        builder: (context) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: ScaffoldColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: ScaffoldInsets.of(context).bodyTopInset + 15,
                ),

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

                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppButton(
                    type: AppButtonType.primary,
                    text: _isEdit ? 'Save Changes' : 'Create Subject',
                    isDisabled: _submitting,
                    onPressed: _submit,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
