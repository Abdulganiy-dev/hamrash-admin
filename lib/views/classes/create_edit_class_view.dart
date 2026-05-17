import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/section_model.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/classes_view_model.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';
import 'package:hamrash_admin/widgets/button/app_button.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/glass_sheet.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

class CreateEditClassView extends StatefulWidget {
  const CreateEditClassView({
    super.key,
    this.existing,
    required this.availableSubjects,
    required this.availableArms,
    required this.viewModel,
  });

  final ClassModel? existing;
  final List<SubjectModel> availableSubjects;
  final List<SectionModel> availableArms;
  final ClassesViewModel viewModel;

  static Future<bool?> openSheet(
    BuildContext context, {
    ClassModel? existing,
    required List<SubjectModel> availableSubjects,
    required List<SectionModel> availableArms,
    required ClassesViewModel viewModel,
  }) {
    final isEdit = existing != null;
    return GlassSheet.show<bool>(
      context: context,
      title: isEdit ? 'Edit Classroom' : 'New Classroom',
      snappingConfig: const SheetSnappingConfig([0.55, 0.92]),
      body: CreateEditClassView(
        existing: existing,
        availableSubjects: availableSubjects,
        availableArms: availableArms,
        viewModel: viewModel,
      ),
    );
  }

  @override
  State<CreateEditClassView> createState() => _CreateEditClassViewState();
}

class _CreateEditClassViewState extends State<CreateEditClassView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedArmName;
  late Set<String> _selectedSubjectIds;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedArmName = widget.existing?.section;
    _selectedSubjectIds = {};
    if (_isEdit) {
      _loadExistingSubjects();
    }
  }

  Future<void> _loadExistingSubjects() async {
    final ids =
        await widget.viewModel.getSubjectIdsForClass(widget.existing!.id!);
    if (mounted) {
      setState(() => _selectedSubjectIds = ids.toSet());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _armPickerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Arm (optional)',
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ).padding(bottom: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: widget.availableArms.isEmpty
              ? AppText(
                  'No arms configured yet.',
                  colorType: AppTextColor.textMute,
                  fontSize: 13,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ArmChipOption(
                        label: 'None',
                        selected: _selectedArmName == null,
                        onTap: () => setState(() => _selectedArmName = null),
                      ),
                      ...widget.availableArms.map((arm) {
                        final selected = _selectedArmName == arm.name;
                        return Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: _ArmChipOption(
                            label: arm.name,
                            selected: selected,
                            onTap: () =>
                                setState(() => _selectedArmName = arm.name),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  List<Widget> _assignSubjectsSection(BuildContext context) {
    if (widget.availableSubjects.isEmpty) return const [];

    return [
      AppText(
        'Assign Subjects',
        colorType: AppTextColor.textInverted,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ).padding(bottom: AppSpacing.sm),
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: List.generate(
              widget.availableSubjects.length,
              (i) {
                final subject = widget.availableSubjects[i];
                final selected = _selectedSubjectIds.contains(subject.id);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i == widget.availableSubjects.length - 1
                        ? 0
                        : AppSpacing.xs,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedSubjectIds.remove(subject.id);
                        } else {
                          _selectedSubjectIds.add(subject.id!);
                        }
                      });
                    },
                    child: AppElevatedCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              subject.name,
                              colorType: AppTextColor.textInverted,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              key: ValueKey(selected),
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    bool success;
    if (_isEdit) {
      success = await widget.viewModel.updateClass(
        existing: widget.existing!,
        name: _nameController.text.trim(),
        section: _selectedArmName,
        subjectIds: _selectedSubjectIds.toList(),
      );
    } else {
      success = await widget.viewModel.createClass(
        name: _nameController.text.trim(),
        section: _selectedArmName,
        subjectIds: _selectedSubjectIds.toList(),
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
              label: 'Class Name',
              hintText: 'e.g. JSS 1, SS 2, Primary 3',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a class name' : null,
            ).padding(bottom: AppSpacing.md),
            _armPickerSection(context),
            ..._assignSubjectsSection(context),
            AppButton(
              type: AppButtonType.primary,
              text: _isEdit ? 'Save Changes' : 'Create Classroom',
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

class _ArmChipOption extends StatelessWidget {
  const _ArmChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd2,
          vertical: AppSpacing.xsSm,
        ),
        decoration: BoxDecoration(
          color: selected ? primary : primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : primary.withValues(alpha: 0.3),
          ),
        ),
        child: AppText(
          label,
          color: selected ? Colors.white : primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
