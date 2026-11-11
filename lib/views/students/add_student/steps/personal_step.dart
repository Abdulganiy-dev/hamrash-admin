import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_health.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/steps/student_step.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/step_lead.dart';
import 'package:hamrash_admin/views/team/widgets/staff_form_fields.dart';

/// 9.6 · Step 2: the student's private details. All are needed except the
/// medical notes; Continue waits for them.
class PersonalStep extends StatelessWidget {
  const PersonalStep({super.key, required this.model});

  final AddStudentViewModel model;

  /// Three lines with 16 above and below: 104 tall, as in the design.
  static const _notesPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.md,
  );

  @override
  Widget build(BuildContext context) => StepScroll(
    children: [
      StepLead(
        eyebrow: model.stepEyebrow(AddStudentStep.personal),
        title: 'More about them',
        body: "School leaders and the student's teachers can see these.",
      ),
      StaffLocationFields(
        stateLabel: 'State of origin',
        state: model.stateOfOrigin,
        lga: model.lga,
        onStateChanged: model.pickStateOfOrigin,
        onLgaChanged: model.pickLga,
      ),
      AppTextField(
        label: 'Home address',
        hintText: '12 Ogui Road, Enugu',
        controller: model.address,

                minLines: 3,
        maxLines: 6,
        contentPadding: _notesPadding,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
    
        onChanged: (_) => model.changed(),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppSelectField<String>(
              label: 'Blood group',
              value: model.bloodGroup,
              items: BloodGroups.values,
              placeholder: 'Select',
              onChanged: model.pickBloodGroup,
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: AppSelectField<String>(
              label: 'Genotype',
              value: model.genotype,
              items: Genotypes.values,
              placeholder: 'Select',
              onChanged: model.pickGenotype,
            ),
          ),
        ],
      ),
      AppTextField(
        label: 'Medical notes',
        isOptional: true,
        optionalStyle: StudentStep.optionalStyle,
        hintText: 'Allergies, conditions or anything a teacher should know',
        controller: model.medicalNotes,
        minLines: 3,
        maxLines: 6,
        contentPadding: _notesPadding,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => model.changed(),
      ),
    ],
  );
}
