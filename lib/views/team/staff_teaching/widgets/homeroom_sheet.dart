import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_load_state.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_note.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';

/// Sets one staff member's homeroom for the current session: the arm, and
/// whether they lead it or assist. Pops `true` when something was saved.
class HomeroomSheet extends StatefulWidget {
  const HomeroomSheet({super.key, required this.model});

  final TeachingSetupViewModel model;

  static Future<bool?> show(
    BuildContext context, {
    required TeachingSetupViewModel model,
  }) => Navigator.of(context).push<bool>(
    AppSheetRoute<bool>(
      size: AppSheetSize.floating,
      child: HomeroomSheet(model: model),
    ),
  );

  @override
  State<HomeroomSheet> createState() => _HomeroomSheetState();
}

class _HomeroomSheetState extends State<HomeroomSheet> {
  SchoolClass? _schoolClass;
  ClassArm? _arm;
  bool _isLead = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Step 1: the classes and arms, from the page's cache when it has them.
    widget.model.loadStructure();
  }

  Future<void> _pickClass() async {
    final picked = await ChoiceListSheet.show<SchoolClass>(
      context: context,
      title: 'Class',
      searchHint: 'Search classes',
      emptyTitle: 'No classes to choose from',
      emptySubtitle: 'Add a class with at least one arm in Classes first.',
      items: widget.model.classes,
      labelBuilder: (schoolClass) => schoolClass.name,
      captionBuilder: (schoolClass) =>
          '${widget.model.armsOf(schoolClass).length} arms',
      selected: _schoolClass,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _schoolClass = picked;
      if (_arm case final arm?
          when !widget.model.armsOf(picked).any((each) => each.id == arm.id)) {
        _arm = null;
      }
    });
  }

  Future<void> _pickArm() async {
    final schoolClass = _schoolClass;
    if (schoolClass == null) return;
    final picked = await ChoiceListSheet.show<ClassArm>(
      context: context,
      title: 'Arm',
      searchHint: 'Search arms',
      emptyTitle: 'No arms in this class',
      emptySubtitle: 'Add an arm to the class first.',
      items: widget.model.armsOf(schoolClass),
      labelBuilder: (arm) => fullArmName(schoolClass.name, arm.name),
      selected: _arm,
    );
    if (picked == null || !mounted) return;
    setState(() => _arm = picked);
    // Step 2: only now, who looks after this arm.
    await widget.model.loadRoster(picked.id);
  }

  Future<void> _save(HomeroomSave save) async {
    final arm = _arm;
    if (!save.canSave || arm == null || _saving) return;
    setState(() => _saving = true);
    final error = await widget.model.saveHomeroom(
      armId: arm.id,
      isLead: _isLead,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _saving = false);
    AppToast.show(error, type: AppToastType.error);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) => _sheet(),
  );

  Widget _sheet() {
    final model = widget.model;
    final ready = !model.structureLoading && model.structureError == null;
    final save = model.homeroomSave(armId: _arm?.id, isLead: _isLead);
    return AppSheet(
      title: 'Set homeroom',
      subtitle: model.hasSession
          ? '${model.schoolYear} · current session'
          : null,
      bodyPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      body: AnimatedSectionContent(
        child: !ready
            ? TeachingLoadState(
                key: ValueKey(
                  model.structureError == null ? 'loading' : 'error',
                ),
                failed: model.structureError != null,
                message: "Couldn't load the classes. Try again.",
                onRetry: model.loadStructure,
              )
            : _form(save),
      ),
      footer: AppPrimaryButton(
        useGradient: true,
        height: 52,
        isDisabled: !ready || !save.canSave || _saving,
        isLoading: _saving,
        loadingText: 'Saving…',
        onPressed: ready && save.canSave && !_saving ? () => _save(save) : null,
        child: Text(save.buttonLabel),
      ),
    );
  }

  Widget _form(HomeroomSave save) => Column(
    key: const ValueKey('form'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppPickerField(
        label: 'Class',
        valueText: _schoolClass?.name,
        placeholder: 'Choose a class',
        enabled: !save.readOnly && !_saving,
        onTap: _pickClass,
      ),
      const SizedBox(height: AppSpacing.ms),
      AppPickerField(
        label: 'Arm',
        valueText: _arm == null ? null : widget.model.armLabel(_arm!.id),
        placeholder: _schoolClass == null
            ? 'Choose a class first'
            : 'Choose an arm',
        enabled: !save.readOnly && !_saving && _schoolClass != null,
        onTap: _pickArm,
      ),
      const SizedBox(height: AppSpacing.md),
      AbsorbPointer(
        absorbing: save.readOnly || _saving,
        child: Opacity(
          opacity: save.readOnly ? 0.5 : 1,
          child: AppSegmentedControl<bool>(
            options: const [
              AppSegmentOption(value: true, label: 'Lead teacher'),
              AppSegmentOption(value: false, label: 'Assistant teacher'),
            ],
            selected: _isLead,
            onChanged: (isLead) => setState(() => _isLead = isLead),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      TeachingNote(note: save.note, tone: save.tone),
    ],
  );
}
