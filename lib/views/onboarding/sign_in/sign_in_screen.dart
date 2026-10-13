import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/onboarding/sign_in/sign_in_view_model.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';
import 'package:stacked/stacked.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.onApplePressed, this.onGooglePressed});

  final Future<void> Function()? onApplePressed;
  final Future<void> Function()? onGooglePressed;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<SignInViewModel>.reactive(
    viewModelBuilder:
        () => SignInViewModel(
          onApplePressed: onApplePressed,
          onGooglePressed: onGooglePressed,
        ),
    builder:
        (context, model, _) => AuthScreenFrame(
          showBackButton: false,
          scrollContent: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppPalette.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPalette.white, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x142A1712),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                          BoxShadow(
                            color: Color(0x332A1712),
                            offset: Offset(0, 8),
                            blurRadius: 20,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'AppIcon/icon_light.png',
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const AppText(
                      'HAMRASH ADMIN',
                      variant: AppTextVariant.overline,
                      colorType: AppTextColor.textBrand,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'Your whole school, in your pocket.',
                      variant: AppTextVariant.display,
                      colorType: AppTextColor.textStrong,
                      height: 46 / 40,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'Classes, staff, results and fees, managed from one place. Sign in, then enter the code your school gave you.',
                      variant: AppTextVariant.bodyLarge,
                      colorType: AppTextColor.textBody,
                    ),
                  ],
                ),
              ),
            ],
          ),
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPrimaryButton(
                      size: AppButtonSize.large,
                      isLoading: model.pending == SignInProvider.apple,
                      isDisabled: model.pending == SignInProvider.google,
                      onPressed: () => model.signIn(SignInProvider.apple),
                      child: const AuthProviderLabel(
                        asset: 'assets/svg/apple-logo.svg',
                        tint: AppPalette.white,
                        label: 'Continue with Apple',
                        labelColor: AppPalette.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.ms),
                    AppSecondaryButton(
                      size: AppButtonSize.large,
                      isLoading: model.pending == SignInProvider.google,
                      isDisabled: model.pending == SignInProvider.apple,
                      onPressed: () => model.signIn(SignInProvider.google),
                      child: const AuthProviderLabel(
                        asset: 'assets/svg/google-g.svg',
                        label: 'Continue with Google',
                        labelColor: AppPalette.stone700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: const AuthTermsCopy(),
              ),
            ],
          ),
        ),
  );
}
