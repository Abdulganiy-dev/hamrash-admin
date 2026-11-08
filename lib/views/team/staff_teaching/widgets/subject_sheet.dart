import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_note.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';

/// Sets one subject's teacher in one arm for the current session. Pops
/// `true` when something was saved.
class SubjectSheet extends StatefulWidget {
  const SubjectSheet({
    super.key,
    required this.model,
    required this.onAddSubjects,
  });

  final TeachingSetupViewModel model;

  /// Opens the class's subjects page, so the chosen arm can be given a
  /// curriculum. Called after the sheet closes.
  final Future<void> Function(String classId) onAddSubjects;

  static Future<bool?> show(
    BuildContext context, {
    required TeachingSetupViewModel model,
    required Future<void> Function(String classId) onAddSubjects,
  }) => Navigator.of(context).push<bool>(
    AppSheetRoute<bool>(
      size: AppSheetSize.floating,
      child: SubjectSheet(model: model, onAddSubjects: onAddSubjects),
    ),
  );

  @override
  State<SubjectSheet> createState() => _SubjectSheetState();
}

class _SubjectSheetState extends State<SubjectSheet> {
  SchoolClass? _schoolClass;
  ClassArm? _arm;
  Subject? _subject;
  bool _saving = false;

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
      _arm = null;
      _subject = null;
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
    if (picked == null || !mounted) return;
    setState(() {
      _arm = picked;
      _subject = null;
    });
  }

  Future<void> _pickSubject() async {
    final arm = _arm;
    if (arm == null) return;
    final subjects = widget.model.subjectsOn(arm.id);
    final picked = await ChoiceListSheet.show<Subject>(
      context: context,
      title: 'Subject',
      searchHint: 'Search subjects',
      items: subjects,
      labelBuilder: (subject) => subject.name,
      captionBuilder: (subject) =>
          widget.model.subjectCaptionFor(arm.id, subject),
      selected: _subject,
    );
    if (picked != null && mounted) setState(() => _subject = picked);
  }

  Future<void> _save(SubjectSave save) async {
    final arm = _arm;
    final subject = _subject;
    if (!save.canSave || arm == null || subject == null || _saving) return;
    setState(() => _saving = true);
    final error = await widget.model.saveSubject(
      armId: arm.id,
      subjectId: subject.id,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _saving = false);
    AppToast.show(error, type: AppToastType.error);
  }

  Future<void> _addSubjects() async {
    final classId = _schoolClass?.id;
    if (classId == null) return;
    Navigator.of(context).pop();
    await widget.onAddSubjects(classId);
  }

  @override
  Widget build(BuildContext context) {
    final arm = _arm;
    final hasCurriculum =
        arm != null && widget.model.subjectsOn(arm.id).isNotEmpty;
    final save = widget.model.subjectSave(
      armId: arm?.id,
      subjectId: _subject?.id,
    );
    final subjectValue = switch (arm) {
      null => 'Choose an arm first',
      _ when !hasCurriculum => 'Nothing available',
      _ => _subject?.name,
    };

    return AppSheet(
      title: 'Set subject',
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
            valueText: arm == null ? null : widget.model.armLabel(arm.id),
            placeholder: _schoolClass == null
                ? 'Choose a class first'
                : 'Choose an arm',
            enabled: !save.readOnly && !_saving && _schoolClass != null,
            onTap: _pickArm,
          ),
          const SizedBox(height: AppSpacing.ms),
          AppPickerField(
            label: 'Subject',
            valueText: subjectValue,
            placeholder: 'Choose a subject',
            enabled: !save.readOnly && !_saving && hasCurriculum,
            onTap: _pickSubject,
          ),
          if (save.addSubjects) ...[
            const SizedBox(height: AppSpacing.xs),
            AppSectionAction(
              label: 'Add subjects to this arm',
              icon: AppIcons.plus,
              onPressed: _addSubjects,
            ),
          ],
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
