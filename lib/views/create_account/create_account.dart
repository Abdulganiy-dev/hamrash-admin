import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/resources/utils/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/api/models/supabase_models/role_model.dart';
import 'package:hamrash_admin/viewModel/create_account_view_model.dart';
import 'package:hamrash_admin/views/create_account/widgets/step_details.dart';
import 'package:hamrash_admin/views/create_account/widgets/step_name.dart';
import 'package:hamrash_admin/views/create_account/widgets/step_profile_image.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/step_indicator.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});
  static String routeName = '/create-account';

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CreateAccountViewModel>.reactive(
      viewModelBuilder: () => CreateAccountViewModel(),
      onViewModelReady: (model) => model.init(context),
      builder: (context, model, _) => DefaultScaffold(
        title: null,
        busy: model.busy,
        body: ScaffoldColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppHugeIconButton(
                  hugeIcon: HugeIcons.strokeRoundedArrowLeft01,
                  hugeIconStrokeWidth: 2,
                  hugeIconRasterSize: 35,
                  foregroundColorType: AppButtonForegroundColor.textInverted,
                  onPressed: () => model.goBack(context),
                ),
                Expanded(
                  child: CreateAccountStepIndicator(
                    currentStep: model.currentStep,
                  ),
                ),
              ],
            ).padding(bottom: AppSpacing.lg),
            Expanded(
              child: PageView(
                controller: model.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    child: Form(
                      key: model.formKeyName,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: CreateAccountStepName(
                        viewModel: model,
                        fullNameController: model.fullNameController,
                        emailController: model.emailController,
                        genderDisplayController: model.genderDisplayController,
                        onGenderFieldTap: () async {
                          await ListBottomSheet.show<void, String>(
                            context: context,
                            title: 'Gender',
                            backgroundSnapshotMode: RouteSnapshotMode.animating,
                            snappingConfig: SheetSnappingConfig([0.35]),
                            headerImage: HugeIcon(icon: HugeIcons.strokeRoundedManWoman,color: Colors.red,),
                            items: model.availableGenders,
                            itemBuilder: (context, item, index) {
                              return ListTile(
                                title: AppText(item,colorType: AppTextColor.textInverted,),
                                onTap:() =>  model.selectGender(item),
                              );
                            },
                          );
                        },
                        phoneController: model.phoneController,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Form(
                      key: model.formKeyDetails,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: CreateAccountStepDetails(
                        viewModel: model,
                        stateDisplayController: model.stateDisplayController,
                        roleDisplayController: model.roleDisplayController,
                        locationController: model.locationController,
                        onStateFieldTap: () async {
                    
                          await ListBottomSheet.show<void, String>(
                            context: context,
                            title: 'State',
                            backgroundSnapshotMode:
                                RouteSnapshotMode.animating,
                       
                            headerImage: HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              color: Colors.red,
                            ),
                            items: model.availableStates,
                            itemBuilder: (context, item, index) {
                              return ListTile(
                                title: AppText(
                                  item,
                                  colorType: AppTextColor.textInverted,
                                ),
                                onTap: () => model.selectState(item),
                              );
                            },
                          );
                        },
                        onRoleFieldTap: () async {
                       
                          await ListBottomSheet.show<void, RoleModel>(
                            context: context,
                            title: 'Role',
                            backgroundSnapshotMode:
                                RouteSnapshotMode.animating,
                            snappingConfig: SheetSnappingConfig([0.45]),
                            headerImage: HugeIcon(
                              icon: HugeIcons.strokeRoundedBriefcase01,
                              color: Colors.red,
                            ),
                            items: model.availableRoles,
                            itemBuilder: (context, item, index) {
                              final subtitle = item.description?.trim();
                              return ListTile(
                                title: AppText(
                                  item.displayLabel,
                                  colorType: AppTextColor.textInverted,
                                ),
                                subtitle: subtitle != null && subtitle.isNotEmpty
                                    ? AppText(
                                        subtitle,
                                        colorType: AppTextColor.textMute,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                onTap: () => model.selectRole(item),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  CreateAccountStepProfileImage(
                    onPickImagePressed: () => model.pickImageFromGallery(),
                    selectedImage: model.selectedImage,
                  ),
                ],
              ),
            ),
            AppPrimaryButton(
              width: double.infinity,
              onPressed: () => model.goNext(context),
              child: AppText(
                model.currentStep == CreateAccountStep.profileImage
                    ? 'Done'
                    : 'Continue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class SnappyPagePhysics extends PageScrollPhysics {
  const SnappyPagePhysics({super.parent});

  @override
  SpringDescription get spring {
    return SpringDescription(mass: 0.5, stiffness: 200, damping: 18);
  }

  @override
  SnappyPagePhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPagePhysics(parent: buildParent(ancestor));
  }
}

