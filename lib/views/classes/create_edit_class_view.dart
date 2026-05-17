import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/section_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
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
    required this.availableSections,
    required this.viewModel,
    this.existingClassNames = const [],
  });

  final ClassModel? existing;
  final List<SubjectModel> availableSubjects;
  final List<SectionModel> availableSections;
  final ClassesViewModel viewModel;

  /// Quick-pick class name chips shown only in create mode.
  final List<String> existingClassNames;

  static Future<bool?> openSheet(
    BuildContext context, {
    ClassModel? existing,
    required List<SubjectModel> availableSubjects,
    required List<SectionModel> availableSections,
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
        availableSections: availableSections,
        viewModel: viewModel,
        existingClassNames:
            isEdit ? const [] : viewModel.existingClassNames,
      ),
    );
  }

  @override
  State<CreateEditClassView> createState() => _CreateEditClassViewState();
}

class _CreateEditClassViewState extends State<CreateEditClassView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedSectionName;
  late Set<String> _selectedSubjectIds;
  bool _submitting = false;
  String? _sectionError;
  String? _subjectsError;

  static const _minSubjects = 2;

  bool get _isEdit => widget.existing != null;

  bool get _hasValidSection => _selectedSectionName != null;

  bool get _hasEnoughSubjects =>
      _selectedSubjectIds.length >= _minSubjects;

  /// True if the current name + section combo already exists in another classroom.
  bool get _isDuplicate {
    final name = _nameController.text.trim().toLowerCase();
    final section = _selectedSectionName?.toLowerCase();
    if (name.isEmpty || section == null) return false;
    return widget.viewModel.classes.any(
      (c) =>
          c.id != widget.existing?.id &&
          c.name.toLowerCase() == name &&
          c.section?.toLowerCase() == section,
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedSectionName = widget.existing?.section;
    _selectedSubjectIds = {};
    if (_isEdit) _loadExistingSubjects();
  }

  Future<void> _loadExistingSubjects() async {
    final ids =
        await widget.viewModel.getSubjectIdsForClass(widget.existing!.id!);
    if (mounted) setState(() => _selectedSubjectIds = ids.toSet());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _sectionPickerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Section',
          colorType: AppTextColor.textInverted,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ).padding(bottom: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: widget.availableSections.isEmpty
              ? AppText(
                  'No sections configured yet.',
                  colorType: AppTextColor.textMute,
                  fontSize: 13,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // _SectionChipOption(
                      //   label: 'None',
                      //   selected: _selectedSectionName == null,
                      //   onTap: () =>
                      //       setState(() => _selectedSectionName = null),
                      // ),
                      ...widget.availableSections.map((s) {
                        final selected = _selectedSectionName == s.name;
                        return Padding(
                          padding:
                              const EdgeInsets.only(left: AppSpacing.xs),
                          child: _SectionChipOption(
                            label: s.name,
                            selected: selected,
                            onTap: () => setState(() {
                              _selectedSectionName = s.name;
                              _sectionError = null;
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
        if (_sectionError != null)
          AppText(
            _sectionError!,
            color: LightColors.errorErrorDefault,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ).padding(bottom: AppSpacing.md),
      ],
    );
  }

  List<Widget> _assignSubjectsSection(BuildContext context) {
    return [
      AppText(
        'Assign Subjects',
        colorType: AppTextColor.textInverted,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ).padding(bottom: AppSpacing.xs),
      AppText(
        'Select at least $_minSubjects subjects',
        colorType:_subjectsError != null ? AppTextColor.error : AppTextColor.textMute,
        fontSize: 12,
      ).padding(bottom: AppSpacing.sm),
      if (widget.availableSubjects.isEmpty)
        AppText(
          'No subjects configured yet.',
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ).padding(bottom: AppSpacing.lg)
      else if (widget.availableSubjects.length < _minSubjects)
        AppText(
          'Add at least $_minSubjects subjects in settings before creating a classroom.',
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ).padding(bottom: AppSpacing.lg)
      else ...[
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: List.generate(widget.availableSubjects.length, (i) {
              final subject = widget.availableSubjects[i];
              final selected = _selectedSubjectIds.contains(subject.id);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == widget.availableSubjects.length - 1
                      ? 0
                      : AppSpacing.xs,
                ),
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedSubjectIds.remove(subject.id);
                    } else {
                      _selectedSubjectIds.add(subject.id!);
                    }
                    if (_selectedSubjectIds.length >= _minSubjects) {
                      _subjectsError = null;
                    }
                  }),
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
                ).hapticFeedback(),
              );
            }),
          ),
        ),
      ),
      
      ],
    ];
  }

  bool _validateRequiredFields() {
    final sectionError =
        _hasValidSection ? null : 'Select a section';
    final subjectsError = _hasEnoughSubjects
        ? null
        : 'Select at least $_minSubjects subjects';
    setState(() {
      _sectionError = sectionError;
      _subjectsError = subjectsError;
    });
    return sectionError == null && subjectsError == null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateRequiredFields()) return;
    if (_isDuplicate) return;
    setState(() => _submitting = true);

    final subjectIds = _selectedSubjectIds.toList();
    final section = _selectedSectionName!;

    final bool success;
    if (_isEdit) {
      success = await widget.viewModel.updateClass(
        existing: widget.existing!,
        name: _nameController.text.trim(),
        section: section,
        subjectIds: subjectIds,
      );
    } else {
      success = await widget.viewModel.createClass(
        name: _nameController.text.trim(),
        section: section,
        subjectIds: subjectIds,
      );
    }

    if (mounted) {
      setState(() => _submitting = false);
      if (success) NavigationService.popScreen(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDuplicate = _isDuplicate;
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
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a class name' : null,
            ).padding(bottom: AppSpacing.sm),
            // Quick-pick chips: only shown in create mode when names exist
            if (!_isEdit && widget.existingClassNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.existingClassNames.map((name) {
                      final selected = _nameController.text.trim() == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _nameController.text = name;
                            _nameController.selection =
                                TextSelection.collapsed(offset: name.length);
                          }),
                          child: AbsorbPointer(
                            child: _SectionChipOption(
                              label: name,
                              selected: selected,
                              onTap: () {},
                            ),
                          ),
                        ).hapticFeedback(),
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              const SizedBox(height: AppSpacing.md),
            _sectionPickerSection(context),
            if (isDuplicate) ...[
              AppText(
                '"${_nameController.text.trim()}${_selectedSectionName != null ? ' $_selectedSectionName' : ''}" already exists.',
                color: LightColors.errorErrorDefault,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ).padding(bottom: AppSpacing.md),
            ],
            ..._assignSubjectsSection(context),
            AppButton(
              type: AppButtonType.primary,
              text: _isEdit ? 'Save Changes' : 'Create Classroom',
              isDisabled: _submitting || isDuplicate,
              onPressed: _submit,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionChipOption extends StatelessWidget {
  const _SectionChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = LightColors.strokeColourStrokeMild;
    final selectedColor = LightColors.backgroundBackdropWarm;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd2,
          vertical: AppSpacing.xsSm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : border,
          ),
        ),
        child: AppText(
          label,
          colorType: selected ? AppTextColor.textBrand : AppTextColor.textInverted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ).hapticFeedback();
  }
}
