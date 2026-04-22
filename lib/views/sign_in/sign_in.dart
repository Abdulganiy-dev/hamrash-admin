import 'package:flutter/material.dart';
import 'package:hamrash_admin/assets_util.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/sign_in_view_model.dart';
import 'package:hamrash_admin/widgets/app_button.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});
  static String routeName = '/sign_in';

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late SignInViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SignInViewModel>.reactive(
      viewModelBuilder: () => SignInViewModel(),
      onViewModelReady: (viewModel) {
        this.viewModel = viewModel;
        viewModel.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
        title: viewModel.title,
        busy: viewModel.busy,
        body: ScaffoldColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Center(
              child: SizedBox(
                width: 300,
                child: AppSecondaryButton(
                  width: 300,
                  isLoading: viewModel.busy,
                  onPressed: viewModel.busy ? null : viewModel.signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AssetsUtil.googleLogo,
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return HugeIcon(
                            icon: HugeIcons.strokeRoundedLogout03,
                            size: 20,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      AppText(
                       viewModel.busy ? 'Signing in...' : 'Continue with Google',
                        colorType: AppTextColor.textInverted,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 300,
              child: AppText(
                'By joining, you agree to our Terms of Service and Privacy Policy.',
                colorType: AppTextColor.textMute,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ).padding(top: 16, bottom: AppSpacing.lg),
            ),
          ],
        ),
      ),
    );
  }
}
