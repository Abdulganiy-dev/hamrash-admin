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

class AddClassSheet extends StatefulWidget {
  const AddClassSheet({
    super.key,
    required this.viewModel,
    required this.arms,
    required this.existingClassNames,
    required this.availableSubjects,
  });

  final ClassesViewModel viewModel;
  final List<SectionModel> arms;
  final List<String> existingClassNames;
  final List<SubjectModel> availableSubjects;

  static Future<bool?> openSheet(
    BuildContext context, {
    required ClassesViewModel viewModel,
  }) {
    return GlassSheet.show<bool>(
      context: context,
      title: 'New Classroom',
      snappingConfig: const SheetSnappingConfig([0.6, 0.92]),
      body: AddClassSheet(
        viewModel: viewModel,
        arms: viewModel.arms,
        existingClassNames: viewModel.existingClassNames,
        availableSubjects: viewModel.subjects,
      ),
    );
  }

  @override
  State<AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends State<AddClassSheet> {
  final _nameController = TextEditingController();
  SectionModel? _selectedArm;
  final Set<String> _selectedSubjectIds = {};
  bool _submitting = false;

  bool get _isDuplicate {
    final name = _nameController.text.trim().toLowerCase();
    final armName = _selectedArm?.name.toLowerCase();
    if (name.isEmpty || armName == null) return false;
    return widget.viewModel.classes.any(
      (c) =>
          c.name.toLowerCase() == name &&
          c.section?.toLowerCase() == armName,
    );
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _selectedArm != null &&
      !_isDuplicate &&
      !_submitting;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    final success = await widget.viewModel.createClass(
      name: _nameController.text.trim(),
      section: _selectedArm!.name,
      subjectIds: _selectedSubjectIds.toList(),
    );
    if (mounted) {
      setState(() => _submitting = false);
      if (success) NavigationService.popScreen(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDuplicate = _isDuplicate;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Class Name',
            hintText: 'e.g. JSS 1, SS 2, Primary 3',
            onChanged: (_) => setState(() {}),
          ),
          if (widget.existingClassNames.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.existingClassNames.map((name) {
                  final selected = _nameController.text.trim() == name;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _nameController.text = name;
                        _nameController.selection = TextSelection.collapsed(
                          offset: name.length,
                        );
                      }),
                      child: _Chip(label: name, selected: selected),
                    ).hapticFeedback(),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppText(
            'Arm',
            colorType: AppTextColor.textInverted,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.arms.isEmpty)
            AppText(
              'No arms yet — add one in the Arms section first.',
              colorType: AppTextColor.textMute,
              fontSize: 13,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.arms.map((arm) {
                  final selected = _selectedArm?.id == arm.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedArm = arm),
                      child: _Chip(label: arm.name, selected: selected),
                    ).hapticFeedback(),
                  );
                }).toList(),
              ),
            ),
          if (isDuplicate) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '"${_nameController.text.trim()} ${_selectedArm!.name}" already exists.',
              color: LightColors.errorErrorDefault,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ],
          if (widget.availableSubjects.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AppText(
              'Assign Subjects',
              colorType: AppTextColor.textInverted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSurfaceCard(
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
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            type: AppButtonType.primary,
            text: 'Create Classroom',
            isDisabled: !_canSubmit,
            onPressed: _submit,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = LightColors.strokeColourStrokeMild;
    final selectedColor = LightColors.backgroundBackdropWarm;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd2,
        vertical: AppSpacing.xsSm,
      ),
      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? selectedColor : primary,
        ),
      ),
      child: AppText(
        label,
        colorType:selected ? .textBrand : .textInverted,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}
