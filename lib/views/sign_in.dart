import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/assets_util.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/viewModel/sign_in_view_model.dart';
import 'package:hamrash_admin/widgets/app_button.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            SizedBox(
              width: 300,
              child: AppButton(
                type: AppButtonType.primary,
                backgroundColorType: AppButtonBackgroundColor.primary,

                textStyle: TextStyle(color: Colors.white),
                isLoading: viewModel.busy,
                onPressed: viewModel.busy ? null : viewModel.signInWithGoogle,
                text: viewModel.busy ? 'Signing in...' : 'Continue with Google',
                customLabel: viewModel.busy
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AssetsUtil.googleLogo,
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.login, size: 20);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Continue with Google',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(
              width: 300,
              child: AppText(
                'By joining, you agree to our Terms of Service and Privacy Policy.',
                colorType: AppTextColor.textMute,
                fontSize: 13,
                fontWeight: FontWeight.normal,
                textAlign: TextAlign.center,
              ).padding(top: 16),
            ),
          ],
        ),
      ),
    );
  }
}
