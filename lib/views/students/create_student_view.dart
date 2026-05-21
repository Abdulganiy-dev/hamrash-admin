import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/create_student_view_model.dart';
import 'package:hamrash_admin/viewModel/students_view_model.dart';
import 'package:hamrash_admin/views/students/student_detail_view.dart';
import 'package:hamrash_admin/views/students/widgets/student_step_academic.dart';
import 'package:hamrash_admin/views/students/widgets/student_step_identity.dart';
import 'package:hamrash_admin/views/students/widgets/student_step_personal.dart';
import 'package:hamrash_admin/views/students/widgets/student_step_photo.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/haptic_list_tile.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

class CreateStudentView extends StatefulWidget {
  const CreateStudentView({
    super.key,
    required this.studentsViewModel,
    this.existing,
  });

  final StudentsViewModel studentsViewModel;
  final StudentModel? existing;

  @override
  State<CreateStudentView> createState() => _CreateStudentViewState();
}

class _CreateStudentViewState extends State<CreateStudentView> {
  late CreateStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return ViewModelBuilder<CreateStudentViewModel>.reactive(
      viewModelBuilder: () =>
          CreateStudentViewModel(existing: widget.existing),
      onViewModelReady: (m) {
        model = m;
        m.init();
      },
      builder: (context, m, _) => DefaultScaffold(
        title: null,
        busy: m.busy,
        appBarType: DefaultScaffoldAppBarType.custom,
        appBarHeight: kToolbarHeight,
        customAppBar: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-AppSpacing.md, 0),
              child: AppHugeIconButton(
                hugeIcon: HugeIcons.strokeRoundedArrowLeft01,
                hugeIconStrokeWidth: 2,
                hugeIconRasterSize: 35,
                foregroundColorType: AppButtonForegroundColor.textInverted,
                onPressed: () => _handleBack(context, m),
              ),
            ).padding(left: AppSpacing.md),
            Expanded(child: _StepProgressBar(step: m.currentStep)),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: ScaffoldColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PageView(
                  controller: m.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SingleChildScrollView(
                      child: Form(
                        key: m.formKeyIdentity,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: StudentStepIdentity(
                          viewModel: m,
                          firstNameController: m.firstNameController,
                          lastNameController: m.lastNameController,
                          emailController: m.emailController,
                          phoneController: m.phoneController,
                        ).padding(top: AppSpacing.xl),
                      ),
                    ),
                    SingleChildScrollView(
                      child: StudentStepPersonal(
                        viewModel: m,
                        onGenderFieldTap: () => _showGenderPicker(context, m),
                        onStateFieldTap: () => _showStatePicker(context, m),
                        onDobFieldTap: () => _pickDate(
                          context: context,
                          initial: m.dateOfBirth,
                          firstYear: DateTime.now().year - 30,
                          lastYear: DateTime.now().year,
                          onPicked: m.setDateOfBirth,
                        ),
                      ).padding(top: AppSpacing.xl),
                    ),
                    SingleChildScrollView(
                      child: StudentStepAcademic(
                        viewModel: m,
                        onClassFieldTap: () => _showClassPicker(context, m),
                        onAdmissionDateTap: () => _pickDate(
                          context: context,
                          initial: m.admissionDate,
                          firstYear: DateTime.now().year - 10,
                          lastYear: DateTime.now().year + 1,
                          onPicked: m.setAdmissionDate,
                        ),
                      ).padding(top: AppSpacing.xl),
                    ),
                    StudentStepPhoto(
                      onPickImagePressed: m.pickImageFromGallery,
                      selectedImage: m.selectedImage,
                      existingAvatarUrl: m.existingAvatarUrl,
                    ).padding(top: AppSpacing.lg),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: keyboardOpen ? 0 : 1,
                child: IgnorePointer(
                  ignoring: keyboardOpen,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: AppPrimaryButton(
                      width: double.infinity,
                      onPressed: () => _handleContinue(context, m),
                      child: AppText(
                        m.isLastStep
                            ? (m.isEdit ? 'Save Changes' : 'Done')
                            : 'Continue',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, CreateStudentViewModel m) {
    if (m.currentStep == CreateStudentStep.identity) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } else {
      m.goBack();
    }
  }

  Future<void> _handleContinue(
    BuildContext context,
    CreateStudentViewModel m,
  ) async {
    if (!m.isLastStep) {
      m.goNext();
      return;
    }
    final result = await m.submit();
    if (result == null || !context.mounted) return;

    if (m.isEdit) {
      widget.studentsViewModel.replaceStudent(result);
      Navigator.of(context).pop(result);
    } else {
      widget.studentsViewModel.addStudent(result);
      await Navigator.pushReplacement(
        context,
        NavigationService.generalPageRouteBuilder(
          screen: StudentDetailView(
            student: result,
            studentsViewModel: widget.studentsViewModel,
          ),
        ),
      );
    }
  }

  Future<void> _showGenderPicker(
    BuildContext context,
    CreateStudentViewModel m,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ListBottomSheet.show<void, String>(
      context: context,
      title: 'Gender',
      backgroundSnapshotMode: RouteSnapshotMode.animating,
      snappingConfig: SheetSnappingConfig([0.35]),
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedManWoman,
        color: Colors.blue,
        size: 30,
        strokeWidth: 2,
      ),
      items: m.availableGenders,
      itemBuilder: (context, item, index) => HapticListTile(
        title: AppText(item, colorType: AppTextColor.textInverted),
        onTap: () => m.selectGender(item),
      ),
    );
  }

  Future<void> _showStatePicker(
    BuildContext context,
    CreateStudentViewModel m,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ListBottomSheet.show<void, String>(
      context: context,
      title: 'State',
      backgroundSnapshotMode: RouteSnapshotMode.animating,
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedLocation01,
        size: 30,
        strokeWidth: 2,
        color: Colors.green,
      ),
      items: m.availableStates,
      itemBuilder: (context, item, index) => HapticListTile(
        title: AppText(item, colorType: AppTextColor.textInverted),
        onTap: () => m.selectState(item),
      ),
    );
  }

  Future<void> _showClassPicker(
    BuildContext context,
    CreateStudentViewModel m,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ListBottomSheet.show<void, ClassModel>(
      context: context,
      title: 'Select class',
      backgroundSnapshotMode: RouteSnapshotMode.animating,
      headerImage: const HugeIcon(
        icon: HugeIcons.strokeRoundedSchool,
        size: 30,
        strokeWidth: 2,
        color: Colors.blueAccent,
      ),
      items: m.availableClasses,
      itemBuilder: (context, cls, index) => HapticListTile(
        title: AppText(
          cls.displayName,
          colorType: AppTextColor.textInverted,
        ),
        onTap: () => m.selectClass(cls),
      ),
    );
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initial,
    required int firstYear,
    required int lastYear,
    required ValueChanged<DateTime> onPicked,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(firstYear),
      lastDate: DateTime(lastYear, 12, 31),
    );
    if (picked != null) onPicked(picked);
  }
}

// ─── Step Progress Bar ────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.step});

  final CreateStudentStep step;

  @override
  Widget build(BuildContext context) {
    final fraction =
        (step.index + 1) / CreateStudentStep.values.length;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) => LinearProgressIndicator(
        backgroundColor:
            LightColors.primaryPrimaryDefault.withValues(alpha: 0.1),
        color: LightColors.primaryPrimaryDefault,
        value: value,
        minHeight: 6,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
