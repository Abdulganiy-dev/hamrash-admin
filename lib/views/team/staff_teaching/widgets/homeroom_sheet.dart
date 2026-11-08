import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';
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
    final home = widget.model.homeroom;
    if (home == null) return;
    _arm = widget.model.armById(home.armId);
    _schoolClass = widget.model.classForArm(home.armId);
    _isLead = home.isLead;
  }

  Future<void> _pickClass() async {
    final picked = await ChoiceListSheet.show<SchoolClass>(
      context: context,
      title: 'Class',
      searchHint: 'Search classes',
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
      items: widget.model.armsOf(schoolClass),
      labelBuilder: (arm) => fullArmName(schoolClass.name, arm.name),
      captionBuilder: (arm) => widget.model.armCaption(arm.id),
      selected: _arm,
    );
    if (picked != null && mounted) setState(() => _arm = picked);
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
  Widget build(BuildContext context) {
    final save = widget.model.homeroomSave(armId: _arm?.id, isLead: _isLead);
    return AppSheet(
      title: 'Set homeroom',
      subtitle: widget.model.hasSession
          ? '${widget.model.schoolYear} · current session'
          : null,
      bodyPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      body: Column(
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
      ),
      footer: AppPrimaryButton(
        useGradient: true,
        height: 52,
        isDisabled: !save.canSave || _saving,
        isLoading: _saving,
        loadingText: 'Saving…',
        onPressed: save.canSave && !_saving ? () => _save(save) : null,
        child: Text(save.buttonLabel),
      ),
    );
  }
}
