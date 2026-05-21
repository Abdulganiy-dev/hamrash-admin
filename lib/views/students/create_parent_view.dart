import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/viewModel/create_parent_view_model.dart';
import 'package:hamrash_admin/views/students/widgets/parent_step_identity.dart';
import 'package:hamrash_admin/views/students/widgets/parent_step_personal.dart';
import 'package:hamrash_admin/views/students/widgets/parent_step_photo.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/haptic_list_tile.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// Multi-step create/edit screen for a parent. On Done, pops with the saved
/// [ParentModel] — the caller is responsible for linking the parent to a
/// student (with a relationship + primary flag).
class CreateParentView extends StatefulWidget {
  const CreateParentView({super.key, this.existing});

  final ParentModel? existing;

  @override
  State<CreateParentView> createState() => _CreateParentViewState();
}

class _CreateParentViewState extends State<CreateParentView> {
  late CreateParentViewModel model;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return ViewModelBuilder<CreateParentViewModel>.reactive(
      viewModelBuilder: () =>
          CreateParentViewModel(existing: widget.existing),
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
                        child: ParentStepIdentity(viewModel: m)
                            .padding(top: AppSpacing.xl),
                      ),
                    ),
                    SingleChildScrollView(
                      child: ParentStepPersonal(
                        viewModel: m,
                        onGenderFieldTap: () => _showGenderPicker(context, m),
                        onStateFieldTap: () => _showStatePicker(context, m),
                      ).padding(top: AppSpacing.xl),
                    ),
                    ParentStepPhoto(
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

  void _handleBack(BuildContext context, CreateParentViewModel m) {
    if (m.currentStep == CreateParentStep.identity) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } else {
      m.goBack();
    }
  }

  Future<void> _handleContinue(
    BuildContext context,
    CreateParentViewModel m,
  ) async {
    if (!m.isLastStep) {
      m.goNext();
      return;
    }
    final result = await m.submit();
    if (result == null || !context.mounted) return;
    Navigator.of(context).pop(result);
  }

  Future<void> _showGenderPicker(
    BuildContext context,
    CreateParentViewModel m,
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
    CreateParentViewModel m,
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
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.step});

  final CreateParentStep step;

  @override
  Widget build(BuildContext context) {
    final fraction = (step.index + 1) / CreateParentStep.values.length;
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
