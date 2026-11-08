import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_load_state.dart';
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
  SubjectOffering? _subject;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Step 1: the classes and arms, shared with the homeroom sheet.
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
      emptyTitle: 'No arms in this class',
      emptySubtitle: 'Add an arm to the class first.',
      items: widget.model.armsOf(schoolClass),
      labelBuilder: (arm) => fullArmName(schoolClass.name, arm.name),
      selected: _arm,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _arm = picked;
      _subject = null;
    });
    // Step 3: only now, what this arm takes and who teaches it.
    await widget.model.loadArmSubjects(picked.id);
  }

  Future<void> _pickSubject() async {
    final arm = _arm;
    if (arm == null) return;
    final subjects = widget.model.subjectsOn(arm.id);
    final picked = await ChoiceListSheet.show<SubjectOffering>(
      context: context,
      title: 'Subject',
      searchHint: 'Search subjects',
      emptyTitle: 'No subjects on this arm',
      emptySubtitle: 'Add subjects to the arm first.',
      items: subjects,
      labelBuilder: (subject) => subject.name,
      captionBuilder: widget.model.subjectCaptionFor,
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
      subjectId: subject.subjectId,
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) => _sheet(),
  );

  Widget _sheet() {
    final model = widget.model;
    final ready = !model.structureLoading && model.structureError == null;
    final save = model.subjectSave(
      armId: _arm?.id,
      subjectId: _subject?.subjectId,
    );
    return AppSheet(
      title: 'Set subject',
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

  Widget _form(SubjectSave save) {
    final arm = _arm;
    final hasCurriculum =
        arm != null && widget.model.subjectsOn(arm.id).isNotEmpty;
    final subjectValue = switch (arm) {
      null => 'Choose an arm first',
      _ when widget.model.armSubjectsLoading(arm.id) => 'Loading…',
      _ when !hasCurriculum => 'Nothing available',
      _ => _subject?.name,
    };
    return Column(
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
    );
  }
}
